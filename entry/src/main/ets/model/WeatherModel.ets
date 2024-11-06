import {forecasts} from "./forecasts"

export class WeatherModel{
  status:number = 0
  infocode: number = 0
  forecasts:Array<forecasts> = []
}
