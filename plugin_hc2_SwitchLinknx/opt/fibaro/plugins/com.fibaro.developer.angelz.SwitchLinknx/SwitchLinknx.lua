-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Name: VoletsLinknx
-- Type: Plugin
-- Version:	1.0.0 beta
-- Release date: 20-10-2014
-- Author: Fabrice Bernardi
-------------------------------------------------------------------------------------------

--! includes
require('common.device')
require('net.HTTPClient')

class 'SwitchLinknx' (Device)
local ip_hc2
local globalConfigured
--! Initializes Free SMS Service (SwitchLinknx class) plugin object.
--@param id: Id of the device.
function SwitchLinknx:__init(id)

    Device.__init(self, id)
    self.http = net.HTTPClient({ timeout = 10000 })
    self:updateProperty('ui.deviceIcon',2)
    self:test_prop()
end


function SwitchLinknx:test_prop()
  local configured = false
  
  local ip_nodejs = self.properties.ip_nodejs
  local port_nodejs = self.properties.port_nodejs
  local id_linknx_cmd = self.properties.id_linknx_cmd
  local id_linknx_status = self.properties.id_linknx_status

  if(ip_nodejs == '' or ip_nodejs == 'undefined') then
    configured = false
  else
    configured = true
  end
  
  if(port_nodejs == '' or port_nodejs == 'undefined') then
    configured = false
  else
    configured = true
  end

  if(id_linknx_cmd == '' or id_linknx_cmd == 'undefined') then
    configured = false
  else
    configured = true
  end

  if(id_linknx_status == '' or id_linknx_status == 'undefined') then
    configured = false
  else
    configured = true
  end

  
  if(tostring(configured) == 'true') then
    self:updateProperty('configured',true)
    globalConfigured = true;
    self:updateProperty('ui.debug.caption', '')
    self:get_ip_hc2()  
  else
    self:updateProperty('configured',false)
    self:updateProperty('ui.debug.caption', 'Paramètres de configuration Manquant')
    globalConfigured = false
   -- self.test_prop(id)
  end
  --self:init_temp_piece()
end


function SwitchLinknx:get_ip_hc2()
    local url = 'http://127.0.0.1:11111/api/settings/network'
    self.headers = {
            }
     self.http:request(url, {
        options = {
            method = 'GET',
            headers = self.headers
        },
        success = function(response) 
           if (response.status == 200 and response.data) then
              local result_json = json.decode(response.data)
                if result_json.ip then
                   ip_hc2 = tostring(result_json.ip)
                    self:init_state()
              end
            end
        end,
        error = function(err) print(err) end
    })
end


--! Prepares HTTPClient object to do http request on freebox
--@param url The url
function SwitchLinknx:httpRequest(url)
	--self:updateProperty('ui.debug.caption',url)
	self.headers = {
            }
	 self.http:request(url, {
        options = {
            method = 'GET',
            headers = self.headers
        },
        success = function(data) print(data.status) end,
        error = function(err) print(err) end
    })
end


--! [public] Restart action
function SwitchLinknx:restartPlugin()
  plugin.restart()
end


function SwitchLinknx:receive_data(id,value)
    if (globalConfigured == true) then
      value = tostring(value)
      id = tostring(id)
      local id_linknx_status = self.properties.id_linknx_status
      if (tostring(id_linknx_status) == id) then
        if (value == 'on') then
            self:turnOn()
            self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff1.png') 
        elseif (value == 'off') then
            self:turnOff()
            self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff0.png')  
        end
      end
    end
end

function SwitchLinknx:turnOn()
  if (globalConfigured == true) then
    local ip_nodejs = self.properties.ip_nodejs
    local port_nodejs = self.properties.port_nodejs
    local id_linknx_cmd = self.properties.id_linknx_cmd
    local url = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/send_cmd?demande=linknx&id=' .. id_linknx_cmd .. '&value=on'
      
    self:httpRequest(url)
    self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff1.png') 
    self:updateProperty('value',true) 
  -- self:updateProperty('deviceIcon','http://' .. ip_hc2 .. '/fibaro/icons/light/light100.png')
  end   
end


function SwitchLinknx:turnOff()
  if (globalConfigured == true) then
    local ip_nodejs = self.properties.ip_nodejs
    local port_nodejs = self.properties.port_nodejs
    local id_linknx_cmd = self.properties.id_linknx_cmd
    local url = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/send_cmd?demande=linknx&id=' .. id_linknx_cmd .. '&value=off'

    self:httpRequest(url)
    self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff0.png')  
    self:updateProperty('value',false)   
  end 
end

function SwitchLinknx:init_state()
  if (globalConfigured == true) then
    local ip_nodejs = self.properties.ip_nodejs
    local port_nodejs = self.properties.port_nodejs
    local id_linknx_status = self.properties.id_linknx_status
    local url = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/etat_linknx_1_obj?id_linknx=' .. id_linknx_status 

    self.headers = {
              }
     self.http:request(url, {
          options = {
              method = 'GET',
              headers = self.headers
          },
          success = function(response) 
              if (response.status == 200 and response.data) then
                local result_json = json.decode(response.data)  
                if result_json.objects then
                  if result_json.objects[1] then
                       local objet = result_json.objects[1]
                       local objet_json = objet
                       local id_linknx  = objet_json.id
                       local value  = objet_json.value
                      if (tostring(id_linknx_status) == tostring(id_linknx)) then
                         if (tostring(value) == 'on') then
                             self:turnOn()
                              self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff1.png') 
                          elseif (tostring(value) == 'off') then
                              self:turnOff()
                              self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.SwitchLinknx/img/onoff0.png')  
                          end
                        end
                  end
                end
              end
          end,
          error = function(err) self:updateProperty('ui.debug.caption', 'Err : ' .. err) end
      })
  end
end




