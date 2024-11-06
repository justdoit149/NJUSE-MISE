import preferences from '@ohos.data.preferences';

class PreferencesUtils {
  // prefMap: Map<string, preferences.Preferences> = new Map()
  pref: preferences.Preferences | null = null

  // 加载数据load
  async loadPreference(context: Context, name: string) {
    try {
      const pref = await preferences.getPreferences(context, name)
      this.pref = pref
      console.log('加载成功')
    } catch (e) {
      console.log('加载失败');
      
    }
  }

  // 新增数据put
  async putPreferenceValue(key: string, value: preferences.ValueType) {
    try {
      if(this.pref != null){
        await this.pref.put(key, value)
        await this.pref.flush()
      }
    } catch (e) {
      console.log('保存失败');
    }
  }

  // 读取数据get
  async getPreferenceValue(key: string, defaultValue: preferences.ValueType) {
    try {
      if(this.pref != null){
        const value = await this.pref.get(key, defaultValue)
        return value
      }else{
        return null
      }
    } catch (e) {
      console.log('读取失败');
      return null
    }
  }

  // 读取所有数据get
  async getAllPreferenceValue() {
    try {
      if(this.pref != null){
        const value = await this.pref.getAll()
        return value
      }else{
        return null
      }
    } catch (e) {
      console.log('读取失败');
      return null
    }
  }

  // 删除数据del
  async delPreferenceValue(key: string) {
    try {
      if(this.pref != null){
        await this.pref.delete(key)
        await this.pref.flush()
      }
    } catch (e) {
      console.log('删除失败');
    }
  }
}

const preferenceUtils = new PreferencesUtils()

export default preferenceUtils as PreferencesUtils