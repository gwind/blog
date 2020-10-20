---
date: "2020-10-20"
title: 保护你的挂载目录里的数据
tags: [tips, linux]
---

我们经常有挂载 ( `mount` ) 网络存储等需求，这是需要现在本机 ( `host` ) 创建一个挂载点，如 `/data` 。
然后通过 `mount` 命令挂载一个存储对象到这个挂载点。

这时，如果忘记挂载，而我们程序已经启动，这是产生的数据就不会保存到我们期望的存储对象上，很容易造成数据丢失。

针对上面的场景，我们只需要在创建挂载点目录时，设置一个属性，即可保证如果没有挂载存储对象，则写入失败。
进而提醒我们需要解决这个 **错误** ，再启动应用。

## 试验

创建一个目录（准备用做挂载点）

```shell
mkdir /mnt/a
```

为这个目录增加不可修改属性 ( `immutable (i)` )

```shell
chattr +i /mnt/a
```

测试该目录是否可以写入文件

```shell
touch /mnt/a/hello.txt
```

我们发现，出现了下面错误：

```text
touch: setting times of '/mnt/a/hello.txt': No such file or directory
```

现在，我们挂载一个 NFS 存储到该目录：

```shell
mount -t nfs -o proto=tcp,port=2049,rw,nolock,nfsvers=4 192.168.122.10:/share /mnt/a/
```

现在，再次测试该目录是否可写：

```shell
touch /mnt/a/hello.txt
```

成功写入，查看文件属性正常：

```plain
# stat /mnt/a/hello.txt
  File: /mnt/a/hello.txt
  Size: 0         	Blocks: 0          IO Block: 1048576 regular empty file
Device: 2eh/46d	Inode: 201326762   Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2020-10-20 11:00:40.649614344 +0800
Modify: 2020-10-20 11:00:40.649614344 +0800
Change: 2020-10-20 11:00:40.649614344 +0800
 Birth: -
```
