import http from '@ohos.net.http';
import {BusinessError} from '@ohos.base'
import { GeoModel } from '../model/GeoModel';
import { router, UIContext } from '@kit.ArkUI';
import PreferencesUtils from '../Util/PreferencesUtils';

class routerParams {
  src: number
  constructor(str:number) {
    this.src = str;
  }
}

function showToast(uiContext: UIContext, info: string){
  try {
    uiContext.getPromptAction().showToast({
      message: info,
      duration: 2000
    })
  } catch (error) {
    let message = (error as BusinessError).message;
    let code = (error as BusinessError).code;
    console.error(`showToast args error code is ${code}, message is ${message}`);
  };
}

@Entry
@Component
struct  Index { // 页面跳转：https://developer.huawei.com/consumer/cn/training/course/slightMooc/C101717497122909477
  @State geoKey: string = '70472d6f980aad13558b550e93868f25'

  @State geoUrl: string = 'https://restapi.amap.com/v3/config/district?key='+this.geoKey+'&keywords='

  @State cityMap: Map<string, number> = new Map()

  @State cityNames: string[] = []

  @State cityName: string | null = null

  @State cityCode: number = 0

  @State editMode: boolean = false

  @State uiContext: UIContext = this.getUIContext() // 由于不支持this绑定，为解决this指针问题，有些地方需要使用它。

  async aboutToAppear(){
    await this.refreshDbStr()
  }

  async refreshDbStr(){
    let db = await PreferencesUtils.getAllPreferenceValue()
    let dbStr: string = JSON.stringify(db)

    let cityMapTemp: Map<string, number> = new Map()
    let cityNamesTemp: string[] = []
    if(dbStr.length > 2) {
      dbStr = dbStr.substring(1, dbStr.length - 1)
      let dbStrSub: string[] = dbStr.split(",")
      for (let i = 0; i < dbStrSub.length; i++) {
        let dbStrSubSub: string[] = dbStrSub[i].split(":")
        let strName: string = dbStrSubSub[0]
        strName = strName.substring(1, strName.length - 1)
        let strCode: string = dbStrSubSub[1]
        strCode = strCode.substring(1, strCode.length - 1)
        cityMapTemp.set(strName, Number(strCode))
        cityNamesTemp.push(strName)
      }
    }
    this.cityMap = cityMapTemp
    this.cityNames = cityNamesTemp
  }

  async addCity(cityName: string, cityCode: number) {
    if (cityName && !this.cityMap.has(cityName)){
      await PreferencesUtils.putPreferenceValue(cityName, cityCode)
      await this.refreshDbStr()
    }
  }

  async removeCity(cityName: string) {
    if (cityName && this.cityMap.has(cityName)){
      await PreferencesUtils.delPreferenceValue(cityName)
      await this.refreshDbStr()
    }
  }

  // 调用高德api获取城市信息
  getCityInfo(keywords: string){
    return new Promise<GeoModel>((resolve,reject)=>{
      let request = http.createHttp()
      let url = this.geoUrl + keywords
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

  async getCities(keywords: string){
    const data = await this.getCityInfo(keywords)
    if(data.count == 1){
      this.cityName = data.districts[0].name
      this.cityCode = data.districts[0].adcode
    }else if(data.count == 0){
      showToast(this.uiContext, '该地区不存在')
      this.cityName = null
      this.cityCode = 0
    }else {
      showToast(this.uiContext,'搜索结果不唯一')
      this.cityName = null
      this.cityCode = 0
    }
  }

  build() {
    Column() {
      // 标题
      Flex() {
        Blank() // 空白占位，方便居中
          .layoutWeight(1)
        Stack({alignContent: Alignment.Center}) {
          Text('城市列表')
            .height(60)
            .fontSize(30)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
        }
        .layoutWeight(2)
        Stack({alignContent: Alignment.End}) {
          Text(this.editMode ? "完成" : "编辑")
            .height(60)
            .fontSize(30)
            .textAlign(TextAlign.Center)
            .fontColor(this.editMode ? Color.Red : Color.White)
            .margin({right: 10})
            .onClick(() => {
              this.editMode = !this.editMode
            })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height(60)
      .backgroundColor('#19c8ff')

      Column(){
        // 搜索框
        if(this.editMode){
          Search()
            .backgroundColor(Color.White)
            .onSubmit((res: string) => {
              this.getCities(res).then(() => {
                if (this.cityName != null) {
                  if(this.cityMap.has(this.cityName)) {
                    showToast(this.uiContext, '该地区已添加过')
                  }else{
                    this.uiContext.showAlertDialog({
                      message: "是否将 "+this.cityName+" 加入列表?",
                      alignment: DialogAlignment.Center,
                      primaryButton: { //主按钮
                        value: '确认',
                        action: () => {
                          this.addCity(this.cityName, this.cityCode)
                          showToast(this.uiContext, '添加成功')
                        },
                        fontColor: '#f00'
                      },
                      secondaryButton: { //副按钮
                        value: '取消',
                        action: () => {},
                        fontColor: '#00f'
                      },
                    })
                  }
                }
              })
            })
        }
        // 城市列表
        List(){
          ForEach(this.cityNames, (item: string) => {
            ListItem() {
              Flex() {
                Blank()
                  .layoutWeight(1)
                Stack({alignContent: Alignment.Center}){
                  Text(item)
                    .fontSize(30)
                    .onClick(() => {
                      console.log(item + " " + this.cityMap.get(item))
                      router.pushUrl({
                        url: "pages/WeatherDetail",
                        params: new routerParams(this.cityMap.get(item)) // 传参
                      }).catch((err: Error) => {
                        console.log(err.name);
                      });
                    })
                }
                .layoutWeight(3)
                Stack({alignContent: Alignment.End}) {
                  if(this.editMode){
                    Button('删除')
                      .height(30)
                      .backgroundColor(Color.Red)
                      .onClick(() => {
                        this.uiContext.showAlertDialog({
                          message: "是否将 "+item+" 从列表中删除?",
                          alignment: DialogAlignment.Center,
                          primaryButton: {
                            value: '确认',
                            action: () => {
                              this.removeCity(item)
                              showToast(this.uiContext, "删除成功")
                            },
                            fontColor: '#f00'
                          },
                          secondaryButton: {
                            value: '取消',
                            action: () => {},
                            fontColor: '#00f'
                          },
                        })

                      })
                  }else{
                    Blank()
                  }
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(20)

            }
          })
        }
        .divider({
          strokeWidth: 1,
          startMargin: 20,
          endMargin: 20,
          color: Color.Gray
        }) // 分割线
        .scrollBar(BarState.Auto) // 滚动条
      }
      .width('100%')
      .height('100%')
      .backgroundImage('media/backgroundPicture_default.jpg')
      .backgroundImageSize(ImageSize.Cover)
    }
    .width('100%')
    .height('100%')
  }
}
