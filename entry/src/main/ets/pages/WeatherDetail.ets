import http from '@ohos.net.http'
import {BusinessError} from '@ohos.base'
import {WeatherModel} from '../model/WeatherModel'
import {casts} from '../model/casts'
import { router } from '@kit.ArkUI'
import web_webview from '@ohos.web.webview'


class routerParams {
  src: number = 0
}

@Entry
@Component
struct WeatherDetail { // 所有创建的页面都需要在resource/base/profile/main_pages.json配置
  @State params: routerParams = router.getParams() as routerParams;

  @State cityCode: number = this.params.src;

  @State weatherKey: string = '70472d6f980aad13558b550e93868f25'

  @State weatherUrl: string = 'https://restapi.amap.com/v3/weather/weatherInfo?key='+this.weatherKey+'&city='+this.cityCode+'&extensions=all'

  @State cityName: string = ''

  @State provinceName: string = ''

  @State todayWeather: casts = new casts()

  @State nextWeathers: Array<casts> = []

  async onPageShow(){
    await this.initData()
  }

  // 数据初始化
  async initData(){
    const data: WeatherModel = await this.getForecastWeather()
    this.cityName = data.forecasts[0].city
    this.provinceName = data.forecasts[0].province
    this.todayWeather = data.forecasts[0].casts[0]
    this.nextWeathers.push(data.forecasts[0].casts[1])
    this.nextWeathers.push(data.forecasts[0].casts[2])
    this.nextWeathers.push(data.forecasts[0].casts[3])
  }

  // 选择天气图标
  judgeWeatherImage(item: casts){
    if(item.dayweather.includes('雪')){
      return 'media/weatherIcon_snowy.svg'
    }else if(item.dayweather.includes('雨')){
      return 'media/weatherIcon_rainy.svg'
    }else if(item.dayweather.includes('阴')){
      return 'media/weatherIcon_overcast.svg'
    }else if(item.dayweather.includes('多云')){
      return 'media/weatherIcon_cloudy.svg'
    }else if(item.dayweather.includes('晴')){
      return 'media/weatherIcon_sunny.svg'
    }else{
      return 'media/weatherIcon_unknown.svg'
    }
  }

  // 调用高德api获取天气数据
  getForecastWeather(){
    return new Promise<WeatherModel>((resolve,reject)=>{
      let request = http.createHttp()
      let url= this.weatherUrl
      let options = {
        method: http.RequestMethod.GET,
        header: {'Content-Type':'application/json'},
      } as http.HttpRequestOptions
      let result = request.request(url, options)
      result.then((res)=>{
        if (res.responseCode === 200) {
          resolve(JSON.parse(res.result.toString()));
        } else {
          reject(new Error("Request failed with status " + res.responseCode));
        }
      }).catch((err: BusinessError)=>{
        console.log(err.name);
        reject(err);
      })
    })
  }


  build() {
    Tabs({ barPosition: BarPosition.End }){
      TabContent(){
        Column() {
          titleBar()
          Column({space: 10}){
            Text(this.provinceName + " " + this.cityName)
                .fontSize(30).height(50).width('100%').margin(10).textAlign(TextAlign.Center)
            Text('今日天气：')
              .fontSize(20).fontWeight(800).width('100%')
            Column({space:10}){
              Text('天气情况：'+this.todayWeather.dayweather)
                .fontSize(22).fontColor(Color.Brown)
              Image(this.judgeWeatherImage(this.todayWeather))
                .width(80).height(50).objectFit(ImageFit.Contain)
              Text('气温：'+this.todayWeather.nighttemp+'~'+this.todayWeather.daytemp+'°C')
                .fontSize(22).fontColor(Color.Brown)
            }.width('70%').border({width:1,color:Color.Pink}).margin(20)
            .borderRadius(30).backgroundColor("#ffbabac1").padding(10)
            WebComponent()
          }
          .width('100%')
          .height('100%')
          .padding(10)
          .backgroundImage('media/backgroundPicture_default.jpg')
          .backgroundImageSize(ImageSize.Cover)
        }
        .width('100%')
        .height('100%')
      }
      .tabBar("当前天气")

      TabContent(){
        Column() {
          titleBar()
          Column({space: 10}){
            Text(this.provinceName + " " + this.cityName)
              .fontSize(30).height(50).width('100%').margin(10).textAlign(TextAlign.Center)
            Text('未来三日天气：')
              .fontSize(20).fontWeight(800).width('100%')
            List({space:10}){
              ForEach(this.nextWeathers,(item:casts, index:Number)=>{
                ListItem(){
                  Column({space:10}){
                    Text(item.date)
                      .fontSize(17)
                    Text('白天天气：'+item.dayweather)
                      .fontSize(20).fontColor(Color.Brown)
                    Image(this.judgeWeatherImage(item))
                      .width(80).height(50).objectFit(ImageFit.Contain)
                    Text('气温：'+item.nighttemp + '~' + item.daytemp +'°C')
                      .fontSize(18).fontWeight(800)
                  }.border({width:1,color:Color.Pink}).padding(10).borderRadius(15).backgroundColor("#ffbabac1")
                }.margin(20)
              })
            }
            .listDirection(Axis.Horizontal)//将list方向改为横向
          }
          .width('100%')
          .height('100%')
          .padding(10)
          .backgroundImage('media/backgroundPicture_default.jpg')
          .backgroundImageSize(ImageSize.Cover)
        }
        .width('100%')
        .height('100%')
      }
      .tabBar("预测天气")
    }
  }
}

@Component
struct titleBar {
  build(){
    Flex() {
      Stack({alignContent: Alignment.Start}) {
        Image('media/pageIcon_back.svg')
          .width(40)
          .height(60)
          .objectFit(ImageFit.Contain)
          .padding(4)
          .margin({left: 10})
      }
      .onClick(() => {
        router.back();
      })
      .layoutWeight(1)

      Stack({alignContent: Alignment.Center}) {
        Text('天气详情')
          .height(60)
          .fontSize(30)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
      }
      .layoutWeight(2)

      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height(60)
    .backgroundColor('#19c8ff')
  }
}

@Component
struct WebComponent {
  controller: web_webview.WebviewController = new web_webview.WebviewController()
  build() {
    Column() {
      Text("WebView，使用真机或模拟器")
      Web({ src: 'www.baidu.com', controller: this.controller})
    }
  }
}

