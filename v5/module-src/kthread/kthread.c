#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>

#include <linux/sched.h>
#include <asm/processor.h>
#include <linux/wait.h>
#include <linux/completion.h>
//#include <linux/version.h>

//#define CLASSIC_METHOD

#define DEV_NAME "kthread"
#ifndef CLASSIC_METHOD
#define REGION_NAME "KTHREAD"
#define CLASS_NAME "kthread"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("kernel thread, writing in 2 sec intervals");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t dev_number;
static struct cdev *driver_object;
static struct class *class;
#endif

static struct file_operations fops = {};
static int thread_id = 0;
static DECLARE_COMPLETION( on_exit );

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
    
    
    thread_id=kernel_thread(&thread_run, NULL, CLONE_KERNEL);
    if(!thread_id){
        printk(KERN_ERR DEV_NAME ": error in Thread creation\n");
        return -EIO;
    }
    
    return 0;
}

static void thread_run(void* ignore){
    unsigned long timeout;
        
    daemonize("kthread:%d.", thread_id);
    allow_signal(1); //TODO CHANGE SIGNAL FROM 1
    
    while(1){
        timeout=2 * HZ; // wait 1 second
        timeout=wait_event_interruptible_timeout(wq, (timeout==0), timeout);
        if( !signal_pending(current) ) {
        // TODO CHECK WHAT SIGNAL
        printk(KERN_INFO DEV_NAME ": kernel Thread sleept received signal\n");
        break;
        } else {
        printk(KERN_INFO DEV_NAME ": kernel Thread sleept woke up\n");    
        }
    }
    
    thread_id = 0;
    complete_and_exit( &on_exit, 0 );
}

static void __exit mod_exit(void) {
     if( thread_id ){
         kill_proc(thread_id,1,1); // TODO: CHANGE SIGNAL FROM 1
     }
     wait_for_completion( &on_exit );
    
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
