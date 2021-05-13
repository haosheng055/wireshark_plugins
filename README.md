# wireshark_plugins
基于Lua的wireshark插件，用于特定协议的抓包分析功能

## 一、依赖需求
- wireshark软件（内置了Lua环境）
## 二、检查wireshark版本
插件可能根据不同的lua版本开发，使用者应该确保自己的wireshark版本支持插件使用的Lua版本。
查看方法：
1. 打开wireshark
2. 点击导航栏的 帮助 -> 关于wireshark
3. 找到相应的描述信息：

## 三、导入Lua插件
在wireshark的根目录下找到plugins文件夹，将Lua脚本拷贝到plugins目录下即可
可能的目录结构如下：
- Wireshark
  - 其它文件夹
  - plugins\3.4
    - codecs
    - Wiretap
    - sol.lua

## 四、使用插件
重启wireshark，没有报错信息即可正常使用。


