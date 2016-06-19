#include <linux/cdev.h>
#include <linux/cpufreq.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/timex.h>
#include <linux/workqueue.h>

//#define CLASSIC_METHOD

#define DEV_NAME "timer"
#ifndef CLASSIC_METHOD
#define REGION_NAME "TIMER"
#define CLASS_NAME "timer"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("Module to test the Linux kernel's work queues usage and functionalities");
MODULE_DESCRIPTION("The module will implement a timer called every 2 seconds and print the spent time (in jiffies) and the maximum and minimum time using a work queue");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t dev_number;
static struct cdev *driver_object;
static struct class *class;
#endif

static struct file_operations fops = {};

static atomic_t stop_timer = ATOMIC_INIT(0);
static DECLARE_COMPLETION(timer_completion);
static unsigned long min, max, curr, prev = 0;

static struct workqueue_struct *wq;
static void work_queue_function(struct work_struct *work);
static DECLARE_WORK(wq_obj, work_queue_function);

static void work_queue_function(struct work_struct *work) {
    if (prev) {
        curr = jiffies - prev;
        max = max > curr ? max : curr;
        min = min < curr && min ? min : curr;
        printk(KERN_INFO DEV_NAME ": timer expired after %lu jiffies (min = %lu, max = %lu)\n", curr, min, max);
    }
    prev = jiffies;

    msleep(2000);

    if (atomic_read(&stop_timer)) {
        complete(&timer_completion);
    } else {
        if (queue_work(wq, &wq_obj)) {
            printk(KERN_DEBUG DEV_NAME ": work queue scheduled succesfully\n");
        } else {
            printk(KERN_ERR DEV_NAME ": error in queue_work\n");
        }
    }
}

static int __init mod_init(void) {
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_NAME, &fops)) < 0) {
        printk(KERN_ALERT DEV_NAME ": error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO DEV_NAME ": device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&dev_number, 0, 1, REGION_NAME)) {
        printk(KERN_ERR DEV_NAME ": error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk(KERN_ERR DEV_NAME ": error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, dev_number, 1)) {
        printk(KERN_ERR DEV_NAME ": error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(class, NULL, dev_number, NULL, "%s", DEV_NAME);
    printk(KERN_INFO DEV_NAME ": device init succesfully completed\n");
    #endif

    wq = create_workqueue("work_queue");
    if (queue_work(wq, &wq_obj)) {
        printk(KERN_INFO DEV_NAME ": work queue initialized succesfully\n");
    } else {
        printk(KERN_ERR DEV_NAME ": error in create_workqueue\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }

    return 0;
}

static void __exit mod_exit(void) {
    printk(KERN_DEBUG DEV_NAME ": cancelling timer re-scheduling after next timeout\n");
    atomic_set(&stop_timer, 1);
    wait_for_completion(&timer_completion);

    if (wq) {
        destroy_workqueue(wq);
        printk(KERN_DEBUG DEV_NAME ": work queue destroyed\n");
    } 

    #ifdef CLASSIC_METHOD
    unregister_chrdev(major, DEV_NAME);
    #else
    device_destroy(class, dev_number);
    class_destroy(class);
    cdev_del(driver_object);
    unregister_chrdev_region(dev_number, 1);
    #endif
    printk(KERN_INFO DEV_NAME ": device succesfully unregistered\n");
}

module_init(mod_init);
module_exit(mod_exit);
