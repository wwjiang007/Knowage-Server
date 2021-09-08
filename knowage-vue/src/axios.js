import axios from 'axios'
//import router from './App.routes.js'
import store from './App.store.js'
import authHelper from '@/helpers/commons/authHelper'

axios.defaults.baseURL = process.env.VUE_APP_BASE_URL

axios.interceptors.request.use(
	(config) => {
		config.headers.common['Accept'] = 'application/json; charset=utf-8'
		config.headers.common['Content-Type'] = 'application/json; charset=utf-8'
		if (localStorage.getItem('token')) config.headers.common[process.env.VUE_APP_DEFAULT_AUTH_HEADER] = 'Bearer ' + localStorage.getItem('token')
		return config
	},
	(error) => {
		Promise.reject(error)
	}
)

axios.interceptors.response.use(
	(res) => {
		return res
	},
	function(error) {
		if (error.response.status) {
			if (error.response.status === 401) {
				authHelper.logout()
			}
			if (error.response.status === 500) {
				console.log(500)

				if (error.response.data.errors) {
					if (error.response.data.errors[0].code) {
						let errArray = error.response.data.errors

						for (var idx in errArray) {
							let err = errArray[idx]

							let hints = ''
							for (var hintIdx in err.hints) {
								let hint = err.hints[hintIdx]

								if (idx > 0) hints += '\n' + hint
								else hints += hint
							}
							store.commit('setError', { title: err.message, msg: hints })
						}
					} else {
						store.commit('setError', { title: 'Server error', msg: error.response.data.errors[0].message })
					}
				}
			}
		}
		return Promise.reject(error)
	}
)

export default axios
