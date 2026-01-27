static int my_kthread(void *data)
{
  while (!kthread_should_stop()) {
    do_stuff();
    schedule();
  }
  return 0;
}

static int __init my_init(void)
{
  kthread_run(my_kthread, NULL, "my_app");
  return 0;  // initcall returns normally
}
late_initcall(my_init);
