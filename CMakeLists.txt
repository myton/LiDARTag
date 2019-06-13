cmake_minimum_required (VERSION 2.8.3)
project (lidar_tag)

# CMAKE TWEAKS
#========================================================================
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -O3 -DEIGEN_NO_DEBUG -march=native -Wl,--no-as-needed")

find_package(catkin REQUIRED COMPONENTS
    roscpp
    rospy
    tf
    sensor_msgs
    visualization_msgs
    message_filters
    std_msgs
    velodyne_pointcloud
    roslib
    lidartag_msgs
)
# CHECK THE DEPENDENCIES
# PCL
find_package(PCL 1.2 REQUIRED)
find_package(Boost REQUIRED
             COMPONENTS filesystem system signals regex date_time program_options thread
)
find_package(Eigen3)
if(NOT EIGEN3_FOUND)
  # Fallback to cmake_modules
  find_package(cmake_modules REQUIRED)
  find_package(Eigen REQUIRED)
  set(EIGEN3_INCLUDE_DIRS ${EIGEN_INCLUDE_DIRS})
  set(EIGEN3_LIBRARIES ${EIGEN_LIBRARIES})  # Not strictly necessary as Eigen is head only
  # Possibly map additional variables to the EIGEN3_ prefix.
else()
  set(EIGEN3_INCLUDE_DIRS ${EIGEN3_INCLUDE_DIR})
endif()

catkin_package(
    INCLUDE_DIRS include
    CATKIN_DEPENDS 
    message_filters 
	roscpp 
	sensor_msgs
    std_msgs 
	tf

    DEPENDS
	Eigen3
)

include_directories(
	include 
	${catkin_INCLUDE_DIRS} 
	${PCL_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIRS}
)
link_directories(${PCL_LIBRARY_DIRS})
add_definitions(${PCL_DEFINITIONS})

# COMPILE THE SOURCE
#========================================================================
add_executable(lidar_tag_main src/main.cc src/lidar_tag.cc src/apriltag_utils.cc src/utils.cc src/tag49h14.cc src/tag16h5.cc)
add_dependencies(lidar_tag_main ${${PROJECT_NAME}_EXPORTED_TARGETS}
    ${catkin_EXPORTED_TARGETS})
target_link_libraries(lidar_tag_main 
    ${catkin_LIBRARIES} 
    ${Boost_LIBRARIES}
    ${PCL_LIBRARIES} 
)