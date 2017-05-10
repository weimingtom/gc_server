#coding:utf-8
import sys
import os,os.path,shutil
#删除文件夹
def delete_dir(delete_dir):
	if os.path.isdir(delete_dir):
		shutil.rmtree(delete_dir)#删除
def copyFiles(source,target_dir):
	# source = 'C:\\Program Files\\Coopen\\image\\image_100042'
	# target_dir = 'D:\\My Documents\\My Pictures\\my'
	now = time.strftime('%Y%m%d')
	if isdir(source) != True:
	    print 'Error: source is not a directory'
	    exit()
	k=0
	filelist = listdir(source)
	print(filelist)
	t = 0
	for name in filelist :
	    if name.find('jpg') == -1 and name.find('png') == -1 :
	        del(filelist[t])
	    t = t + 1
	print(filelist)
	#exit()
	for name in filelist :
	    srcFilename = source + '\\' + name
	    srcFilename = '"' + srcFilename + '"'
	    desFilename = target_dir + '\\' + now + '_' + name
	    desFilename = '"' + desFilename + '"'
	    print 
	    copy_command = "copy %s %s" % (srcFilename, desFilename)
	    print copy_command
	    if os.system(copy_command) == 0:
	        k = k + 1
	        print 'Successful backup to copy from', srcFilename, 'to' ,desFilename
	    else:
	        print 'Fail to copy', srcFilename, 'to', desFilename
	print 'total copy', k, 'files'
file_root = os.path.abspath(os.path.dirname(__file__))
#print 'cocos_root:%s' %file_root
#删除以前旧的文件
pb_gen_path = os.path.abspath(os.path.join(file_root, 'client'))
delete_dir(pb_gen_path)
#创建目录
os.mkdir(pb_gen_path)
bat_path = os.path.abspath(os.path.join(file_root,'client_pbcreate_2.bat'))
#执行pb文件生成脚本
os.system(bat_path)
#将生成的协议文件复制到工程目录中去
project_pb_file_path = "E:/workspace/client/new_client/res/hall/res/pb_files"
delete_dir(project_pb_file_path)
#创建目录
os.mkdir(project_pb_file_path)
pbFiles = os.listdir(pb_gen_path)
for name in pbFiles:
	fullname =os.path.join(pb_gen_path,name)
	print "pbfile:%s" %fullname
	shutil.copy(fullname,project_pb_file_path)
#将当前目录的文件下的 common_ 开头的协议文件复制到 工程中去
pb_origin_file_path = "E:/workspace/client/new_client/common/pb"
delete_dir(pb_origin_file_path)
os.mkdir(pb_origin_file_path)
fileList = []  
# 返回一个列表，其中包含在目录条目的名称(google翻译)  
files = os.listdir(file_root)
for name in files:
        fullname =os.path.join(file_root,name)
        if name.endswith('.proto'):
        	if name.startswith('common_'):
        		print fullname
        		shutil.copy(fullname, pb_origin_file_path)
#


