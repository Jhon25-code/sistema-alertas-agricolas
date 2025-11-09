import React, { useState } from 'react'
import AlertPanel from './components/AlertPanel.jsx'
import Dashboard from './components/Dashboard.jsx'

export default function App(){
  const [view, setView] = useState('alert')
  return (
    <div style={{fontFamily:'system-ui, sans-serif', minHeight:'100vh', display:'grid', gridTemplateColumns:'1fr 1fr'}}>
      <div style={{display:'flex', alignItems:'center', justifyContent:'center', background:'#f3f4f6'}}>
        <div style={{textAlign:'center'}}>
          <div style={{fontSize:48}}>🌾</div>
          <h1>SIAAS</h1>
        </div>
      </div>
      <div style={{padding:24}}>
        <div style={{display:'flex', gap:8, marginBottom:12}}>
          <button onClick={()=> setView('alert')}>Nueva alerta</button>
          <button onClick={()=> setView('dashboard')}>Tablero</button>
        </div>
        {view==='alert' ? <AlertPanel /> : <Dashboard />}
      </div>
    </div>
  )
}
