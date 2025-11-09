import React from 'react'

export default function AlertPanel(){
  const incident = { type:'PICADURA DE ABEJA', time:'10:32 AM', location:'Se añadirá al sincronizar', img:'(imagen)' }
  return (
    <div style={{border:'2px solid #e5e7eb', borderRadius:16, padding:16}}>
      <div style={{display:'flex', alignItems:'center', gap:8, marginBottom:12}}>
        <span style={{fontSize:24}}>⚠️</span>
        <h2 style={{margin:0}}>NUEVA ALERTA DE INCIDENTE</h2>
      </div>
      <div style={{border:'2px dashed #cbd5e1', height:160, display:'flex', alignItems:'center', justifyContent:'center', marginBottom:12}}>
        {incident.img}
      </div>
      <div style={{display:'grid', gridTemplateColumns:'160px 1fr', rowGap:8}}>
        <div>TIPO DE INCIDENTE:</div><div><strong>{incident.type}</strong></div>
        <div>HORA:</div><div>{incident.time}</div>
        <div>UBICACIÓN:</div><div>{incident.location}</div>
      </div>
      <div style={{marginTop:16}}>
        <button style={{background:'#ef4444', color:'#fff', padding:'10px 16px', borderRadius:8}}>ALERTA</button>
      </div>
    </div>
  )
}
