import React, { useState } from 'react'

export default function Dashboard(){
  const [incidents] = useState([
    {id:'a1', type:'picadura_abeja', score:90, status:'nuevo', created_at:'10:31'},
    {id:'a2', type:'corte', score:60, status:'en_atencion', created_at:'10:45'},
  ])
  const statusColor = (s)=> s==='nuevo' ? '#ef4444' : s==='en_atencion' ? '#f59e0b' : '#10b981'

  return (
    <div>
      <h2>Tablero</h2>
      <table border="1" cellPadding="6" style={{width:'100%', borderCollapse:'collapse'}}>
        <thead><tr><th>ID</th><th>Tipo</th><th>Score</th><th>Estado</th><th>Hora</th></tr></thead>
        <tbody>
          {incidents.map(x => (
            <tr key={x.id}>
              <td>{x.id}</td>
              <td>{x.type}</td>
              <td>{x.score}</td>
              <td><span style={{background:statusColor(x.status), color:'#fff', padding:'2px 8px', borderRadius:12}}>{x.status}</span></td>
              <td>{x.created_at}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
