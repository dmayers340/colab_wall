#include <iostream>
#include <libfreenect.hpp>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <cmath>
#include <vector>
#include <ctime>
#include <boost/thread/thread.hpp>
#include "pcl/common/common_headers.h"
#include "pcl/features/normal_3d.h"
#include "pcl/io/pcd_io.h"
#include "pcl/visualization/pcl_visualizer.h"
#include "pcl/console/parse.h"
#include "pcl/point_types.h"
#include <pcl/kdtree/kdtree_flann.h>
#include <pcl/surface/mls.h>
#include "boost/lexical_cast.hpp"
#include "pcl/filters/voxel_grid.h"
#include "pcl/octree/octree.h"
#include "BufferedAsyncSerial.h"
using namespace std;
using namespace boost;
///Mutex Class
class Mutex {
public:
 Mutex() {
 pthread_mutex_init( &m_mutex, NULL ); 
 }
 void lock() {
 pthread_mutex_lock( &m_mutex );
 }
void unlock() {
 pthread_mutex_unlock( &m_mutex );
 }
class ScopedLock
 {
 Mutex & _mutex;
public:
 ScopedLock(Mutex & mutex)
 : _mutex(mutex)
 {
 _mutex.lock();
 }
 ~ScopedLock()
 {
 _mutex.unlock();
 }
 };
private:
 pthread_mutex_t m_mutex;
};
///Kinect Hardware Connection Class
/* thanks to Yoda---- from IRC */
class MyFreenectDevice : public Freenect::FreenectDevice {
public:
 MyFreenectDevice(freenect_context *_ctx, int _index)
 : Freenect::FreenectDevice(_ctx, _index),
depth(freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM,
FREENECT_DEPTH_REGISTERED).bytes),m_buffer_video(freenect_find_video_mode(FREENEC
T_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB).bytes), m_new_rgb_frame(false),
m_new_depth_frame(false)
 {

 }
//~MyFreenectDevice(){}
// Do not call directly even in child
void VideoCallback(void* _rgb, uint32_t timestamp) {
 Mutex::ScopedLock lock(m_rgb_mutex);
 uint8_t* rgb = static_cast<uint8_t*>(_rgb);
 std::copy(rgb, rgb+getVideoBufferSize(), m_buffer_video.begin());
 m_new_rgb_frame = true; 
 };
// Do not call directly even in child
void DepthCallback(void* _depth, uint32_t timestamp) {
 Mutex::ScopedLock lock(m_depth_mutex);
 depth.clear();
 uint16_t* call_depth = static_cast<uint16_t*>(_depth);
 for (size_t i = 0; i < 640*480 ; i++) {
 depth.push_back(call_depth[i]);
 }
 m_new_depth_frame = true;
 }
bool getRGB(std::vector<uint8_t> &buffer) {
 //printf("Getting RGB!\n");
 Mutex::ScopedLock lock(m_rgb_mutex);
 if (!m_new_rgb_frame) {
 //printf("No new RGB Frame.\n");
 return false;
 }
 buffer.swap(m_buffer_video);
 m_new_rgb_frame = false;
 return true;
 }
bool getDepth(std::vector<uint16_t> &buffer) {
 Mutex::ScopedLock lock(m_depth_mutex);
 if (!m_new_depth_frame)
 return false;
 buffer.swap(depth);
 m_new_depth_frame = false;
 return true;
 }
private:
 std::vector<uint16_t> depth;
 std::vector<uint8_t> m_buffer_video; 
Mutex m_rgb_mutex;
 Mutex m_depth_mutex;
bool m_new_rgb_frame;
bool m_new_depth_frame;
};
///Start the PCL/OK Bridging
//OK
Freenect::Freenect freenect;
MyFreenectDevice* device;
freenect_video_format requested_format(FREENECT_VIDEO_RGB);
double freenect_angle(0);
int got_frames(0),window(0);
int g_argc;
char **g_argv;
int user_data = 0;
//PCL
pcl::PointCloud<pcl::PointXYZRGB>::Ptr cloud (new
pcl::PointCloud<pcl::PointXYZRGB>);
pcl::PointCloud<pcl::PointXYZRGB>::Ptr bgcloud (new
pcl::PointCloud<pcl::PointXYZRGB>);
pcl::PointCloud<pcl::PointXYZRGB>::Ptr voxcloud (new
pcl::PointCloud<pcl::PointXYZRGB>);
float resolution = 50.0;
// Instantiate octree-based point cloud change detection class
pcl::octree::OctreePointCloudChangeDetector<pcl::PointXYZRGB> octree
(resolution);
bool BackgroundSub = false;
bool hasBackground = false;
bool Voxelize = false;
unsigned int voxelsize = 1; //in mm
unsigned int cloud_id = 0;
///Keyboard Event Tracking
void keyboardEventOccurred (const pcl::visualization::KeyboardEvent &event,
 void* viewer_void)
{
 boost::shared_ptr<pcl::visualization::PCLVisualizer> viewer = 
 {
 boost::shared_ptr<pcl::visualization::PCLVisualizer> viewer =
*static_cast<boost::shared_ptr<pcl::visualization::PCLVisualizer> *>
(viewer_void);
 if (event.getKeySym () == "c" && event.keyDown ())
 {
 std::cout << "c was pressed => capturing a pointcloud" << std::endl;
 std::string filename = "KinectCap";
 filename.append(boost::lexical_cast<std::string>(cloud_id));
 filename.append(".pcd");
 pcl::io::savePCDFileASCII (filename, *cloud);
 cloud_id++;
 } 
  if (event.getKeySym () == "b" && event.keyDown ())
 {
 std::cout << "b was pressed" << std::endl;
 if (BackgroundSub == false)
 {
 //Start background subtraction
 if (hasBackground == false)
 {
 //Copy over the current cloud as a BG cloud.
 pcl::copyPointCloud(*cloud, *bgcloud);
 hasBackground = true;
 }
 BackgroundSub = true;
 }
 else
 {
 //Stop Background Subtraction
 BackgroundSub = false;
 }
 }

 if (event.getKeySym () == "v" && event.keyDown ())
 {
 std::cout << "v was pressed" << std::endl;
 Voxelize = !Voxelize;
 }
}
// --------------
// -----Main-----
// --------------
int main (int argc, char** argv)
{
if (argc != 4)
 {
 cerr << "Usage: OKFlower <baud> <device> <percentage>\n";
 cerr << "Typ: 9600 /de
 v/tty.usbmodemfd131 10\n"; 
 return 1;
 }

 //Percentage Change
 float percentage = boost::lexical_cast<float>(argv[3]);
 percentage = percentage/100.0; 
 //More Kinect Setup
static std::vector<uint16_t> mdepth(640*480);
static std::vector<uint8_t> mrgb(640*480*4);
// Fill in the cloud data
 cloud->width = 640;
 cloud->height = 480;
 cloud->is_dense = false;
 cloud->points.resize (cloud->width * cloud->height);

// Create and setup the viewer
 boost::shared_ptr<pcl::visualization::PCLVisualizer> viewer (new
pcl::visualization::PCLVisualizer ("3D Viewer"));
 viewer->registerKeyboardCallback (keyboardEventOccurred, (void*)&viewer);
 viewer->setBackgroundColor (255, 255, 255);
 viewer->addPointCloud<pcl::PointXYZRGB> (cloud, "Kinect Cloud");
 viewer->setPointCloudRenderingProperties
(pcl::visualization::PCL_VISUALIZER_POINT_SIZE, 1, "Kinect Cloud");
 viewer->addCoordinateSystem (1.0);
 viewer->initCameraParameters ();

//Voxelizer Setup
 pcl::VoxelGrid<pcl::PointXYZRGB> vox;


 device = &freenect.createDevice<MyFreenectDevice>(0);
 device->startVideo();
 device->startDepth();
 boost::this_thread::sleep (boost::posix_time::seconds (1));
//Grab until clean returns
int DepthCount = 0;
while (DepthCount == 0) {
 device->updateState();
 device->getDepth(mdepth);
 device->getRGB(mrgb);
 for (size_t i = 0;i < 480*640;i++)
 DepthCount+=mdepth[i];
 }
 device->setVideoFormat(requested_format); 
 //--------------------
 // -----Main loop-----
//--------------------
double x = NULL;
double y = NULL;
int iRealDepth = 0; 
try {
 //BufferedAsync Setup
 printf("Starting up the BufferedAsync Stuff\n");
 BufferedAsyncSerial serial(argv[2], boost::lexical_cast<unsigned
int>(argv[1]));

while (!viewer->wasStopped ())
 {
 device->updateState();
 device->getDepth(mdepth);
 device->getRGB(mrgb);

 size_t i = 0;
 size_t cinput = 0;
 for (size_t v=0 ; v<480 ; v++)
 {
 for ( size_t u=0 ; u<640 ; u++, i++)
 {
 //pcl::PointXYZRGB result;
 iRealDepth = mdepth[i];
 //DepthCount+=iRealDepth;
 //printf("fRealDepth = %f\n",fRealDepth);
 //fflush(stdout);
 freenect_camera_to_world(device->getDevice(), u, v,
iRealDepth, &x, &y);
 cloud->points[i].x = x;//1000.0;
 cloud->points[i].y = y;//1000.0;
 cloud->points[i].z = iRealDepth;//1000.0;
 cloud->points[i].r = mrgb[i*3];
 cloud->points[i].g = mrgb[(i*3)+1];
 cloud->points[i].b = mrgb[(i*3)+2];
 //cloud->points[i] = result;
 //printf("x,y,z = %f,%f,%f\n",x,y,iRealDepth);
 //printf("RGB = %d,%d,%d\n",
mrgb[i*3],mrgb[(i*3)+1],mrgb[(i*3)+2]);
 }
 }
 if (BackgroundSub) {
 pcl::PointCloud<pcl::PointXYZRGB>::Ptr fgcloud (new
 pcl::PointCloud<pcl::PointXYZRGB>);
 octree.deleteCurrentBuffer();

 // Add points from background to octree
 octree.setInputCloud (bgcloud);
 octree.addPointsFromInputCloud ();
 // Switch octree buffers: This resets octree but keeps
previous tree structure in memory.
 octree.switchBuffers ();

 // Add points from the mixed data to octree
 octree.setInputCloud (cloud);
 octree.addPointsFromInputCloud ();
 std::vector<int> newPointIdxVector;

 // Get vector of point indices from octree voxels which did
not exist in previous buffer
 octree.getPointIndicesFromNewVoxels (newPointIdxVector);

 for (size_t i = 0; i < newPointIdxVector.size(); ++i) {
 fgcloud->push_back(cloud-
>points[newPointIdxVector[i]]);
 }

 viewer->updatePointCloud (fgcloud, "Kinect Cloud");

 printf("Cloud Size: %d vs. Max: %d vs. perc: %f\n",
newPointIdxVector.size(), 640*480,
(float)newPointIdxVector.size()/(float)(640.0*480.0));
 if (((float)newPointIdxVector.size()/(float)(640.0*480.0))
>= percentage) {
 printf("Person in Scene!\n");
 serial.writeString("L");
 }
 else
 serial.writeString("O");
 }
 else if (Voxelize) {
 vox.setInputCloud (cloud); 
 vox.setLeafSize (5.0f, 5.0f, 5.0f);
 vox.filter (*voxcloud);
 viewer->updatePointCloud (voxcloud, "Kinect Cloud");
 }
 else
 viewer->updatePointCloud (cloud, "Kinect Cloud");

 viewer->spinOnce ();
 }
 serial.close();
 } catch(boost::system::system_error& e) 
 {
 cout<<"Error: "<<e.what()<<endl;
 device->stopVideo();
 device->stopDepth();
 return 1;
 }
 device->stopVideo();
 device->stopDepth();
return 0;
} 

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
set(CMAKE_C_FLAGS "-Wall")
project(OKFlower)
find_package(PCL 1.4 REQUIRED)
include_directories(${PCL_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})
add_definitions(${PCL_DEFINITIONS})
if (WIN32)
 set(THREADS_USE_PTHREADS_WIN32 true)
 find_package(Threads REQUIRED)
 include_directories(${THREADS_PTHREADS_INCLUDE_DIR})
endif()
include_directories(. ${PCL_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})
add_definitions(${PCL_DEFINITIONS})
add_executable(OKFlower OKFlower.cpp AsyncSerial.cpp BufferedAsyncSerial.cpp)
if(APPLE)
 target_link_libraries(OKFlower freenect ${PCL_LIBRARIES})
else()
 find_package(Threads REQUIRED)
 include_directories(${USB_INCLUDE_DIRS})
 if (WIN32) 
 set(MATH_LIB "")
 else(WIN32)
 set(MATH_LIB "m")
 endif()
 target_link_libraries(OKFlower freenect ${CMAKE_THREAD_LIBS_INIT} ${MATH_LIB}
${PCL_LIBRARIES})
endif()
