# 目录结构


```
listentogether重点类：
 NEListenTogetherKit.kt     一起听业务组件核心类
 NEListenTogetherRoomListener.kt   一起听房间事件
 ListenTogetherKitImpl NEListenTogetherKit实现
 ListenTogetherHttpServiceImpl 一起听业务网络请求

  listentogetherkit-ui 重点类：
 ListenTogetherAnchorActivity.java      # 一起听功能 主播页面
 ListenTogetherAudienceActivity.java    # 一起听功能 观众页面
 ListenTogetherService    #一起听业务服务
 NEListenTogetherListener    #一起听业务监听器
 ListenTogetherViewModel #一起听ViewModel
 
  ordersong 重点类：
  NEOrderSongService  # 点歌服务
  NEOrderSongListener # 点歌监听
  OrderListFragment     # 点歌列表
  OrderedListFragment  # 已点歌曲列表
```


# 开发环境要求
在开始运行示例项目之前，请确保开发环境满足以下要求：
| 环境要求                                                        | 说明                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
|  JDK 版本  |  1.8.0 及以上版本   |
|  Android API 版本 | API 21、Android Studio 5.0 及以上版本   |
| CPU架构 | ARM 64、ARM V7   |
| IDE | Android Studio  |
| 其他 |  依赖 Androidx，不支持 support 库。android 系统 5.0 及以上版本的真机 |

# 前提条件

请确认您已完成以下操作：
- [已创建应用并获取AppKey](https://doc.yunxin.163.com/jcyOTA0ODM/docs/jcwMDQ2MTg)
- [已开通相关能力](https://doc.yunxin.163.com/docs/TA3ODAzNjE/zQ4MTI0Njc?platformId=50616)


# 运行示例项目

> 注意：
>
>一起听的示例源码仅供开发者接入参考，实际应用开发场景中，请结合具体业务需求修改使用。
>
>若您计划将源码用于生产环境，请确保应用正式上线前已经过全面测试，以免因兼容性等问题造成损失。

1. 克隆示例项目源码仓库至您本地工程。
2. 开启 Android 设备的开发者选项，通过 USB 连接线将 Android 设备接入电脑。
3. 通过 Android Studio 打开项目，在 app\src\main\java\com\netease\yunxin\app\listentogether\config\AppConfig.java  文件中配置应用的 App Key,并填上对应的云信NERoom账号信息。。

```
private static final String APP_KEY_MAINLAND = "your mainland appKey"; // 国内用户填写
private static final String APP_KEY_OVERSEA = "your oversea appKey";// 海外用户填写
// 获取userUuid和对应的userToken，请参考https://doc.yunxin.163.com/neroom/docs/TY1NzM5MjQ?platform=server
public static final String ACCOUNT = "your userUuid";
public static final String TOKEN = "your userToken";
public static final String NICKNAME = "nickname";
```

4. 在 Android Studio 中，单击 Sync Project with Gradle Files 按钮，同步工程依赖。
5. 选中设备直接运行，即可体验 Demo。