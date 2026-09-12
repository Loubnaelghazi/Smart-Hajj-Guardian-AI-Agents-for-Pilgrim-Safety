import {useEffect, useRef} from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {t} from '../i18n';

export default function SafeZoneMap({value, onChange}) {
  const host=useRef(null), map=useRef(null), layer=useRef(null), update=useRef(onChange);
  update.current=onChange;
  const hasPoint=value.latitude !== '' && value.longitude !== '' && Number.isFinite(Number(value.latitude)) && Number.isFinite(Number(value.longitude));
  useEffect(()=>{
    const instance=L.map(host.current).setView(hasPoint?[Number(value.latitude),Number(value.longitude)]:[21.4225,39.8262],15);
    map.current=instance;
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',maxZoom:19}).addTo(instance);
    layer.current=L.layerGroup().addTo(instance);
    instance.on('click',e=>update.current({latitude:Number(e.latlng.lat.toFixed(6)),longitude:Number(e.latlng.wrap().lng.toFixed(6))}));
    const observer=new ResizeObserver(()=>instance.invalidateSize());observer.observe(host.current);
    return ()=>{observer.disconnect();instance.remove();map.current=null;};
  },[]);
  useEffect(()=>{
    if(!map.current)return;
    layer.current.clearLayers();
    if(!hasPoint)return;
    const point=[Number(value.latitude),Number(value.longitude)];
    if(Math.abs(point[0])>90 || Math.abs(point[1])>180)return;
    L.circleMarker(point,{radius:8,color:'#075e49',fillOpacity:1}).addTo(layer.current);
    const radius=Number(value.radius_m);
    if(Number.isFinite(radius)&&radius>0)L.circle(point,{radius,color:'#087a5b',fillOpacity:.15}).addTo(layer.current);
    if(!map.current.getBounds().contains(point))map.current.panTo(point);
  },[value.latitude,value.longitude,value.radius_m,hasPoint]);
  return <div>
    <p style={{margin:'0 0 10px',fontSize:14}}>{t('Click the map to choose the meeting point. Adjust the radius below.')}</p>
    <div ref={host} aria-label={t('Choose a meeting point on the map.')} style={{height:300,borderRadius:12,overflow:'hidden',direction:'ltr'}} />
    <p role="status" style={{fontSize:13,marginTop:8}}>{hasPoint?t('Meeting point selected.'):t('No point selected yet.')}</p>
  </div>;
}
