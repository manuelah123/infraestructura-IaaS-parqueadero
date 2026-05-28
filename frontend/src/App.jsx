import { useEffect, useState } from "react";
import { LogIn, LogOut, Plus, RefreshCw, Save, Trash2, Pencil } from "lucide-react";
import "./App.css";

const API_URL = "http://127.0.0.1:8000";
const KEYCLOAK_TOKEN_URL =
  "http://127.0.0.1:8082/realms/parqueadero/protocol/openid-connect/token";

export default function App() {
  const [token, setToken] = useState(localStorage.getItem("token") || "");
  const [usuario, setUsuario] = useState("");
  const [password, setPassword] = useState("");
  const [vehiculos, setVehiculos] = useState([]);
  const [mensaje, setMensaje] = useState("");
  const [editando, setEditando] = useState(null);

  const [form, setForm] = useState({
    placa: "",
    tipo: "carro",
    estado: "parqueado",
  });

  async function login(e) {
    e.preventDefault();
    setMensaje("");

    const body = new URLSearchParams();
    body.append("client_id", "parking-frontend");
    body.append("username", usuario);
    body.append("password", password);
    body.append("grant_type", "password");

    const res = await fetch(KEYCLOAK_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });

    if (!res.ok) {
      setMensaje("Credenciales invalidas");
      return;
    }

    const data = await res.json();
    localStorage.setItem("token", data.access_token);
    setToken(data.access_token);
    setPassword("");
    setMensaje("Sesion iniciada");
  }

  function logout() {
    localStorage.removeItem("token");
    setToken("");
    setVehiculos([]);
    setMensaje("Sesion cerrada");
  }

  async function cargarVehiculos() {
    const res = await fetch(`${API_URL}/vehiculos`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      setMensaje("No se pudieron cargar los vehiculos");
      return;
    }

    setVehiculos(await res.json());
  }

  async function guardarVehiculo(e) {
    e.preventDefault();

    const url = editando
      ? `${API_URL}/vehiculos/${editando}`
      : `${API_URL}/vehiculos`;

    const method = editando ? "PUT" : "POST";

    const payload = editando
      ? { tipo: form.tipo, estado: form.estado }
      : form;

    const res = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const error = await res.json().catch(() => ({}));
      setMensaje(error.detail || "No se pudo guardar el vehiculo");
      return;
    }

    setForm({ placa: "", tipo: "carro", estado: "parqueado" });
    setEditando(null);
    setMensaje(editando ? "Vehiculo actualizado" : "Vehiculo registrado");
    cargarVehiculos();
  }

  function editarVehiculo(vehiculo) {
    setEditando(vehiculo.placa);
    setForm({
      placa: vehiculo.placa,
      tipo: vehiculo.tipo,
      estado: vehiculo.estado,
    });
  }

  async function eliminarVehiculo(placa) {
    const res = await fetch(`${API_URL}/vehiculos/${placa}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      setMensaje("No se pudo eliminar el vehiculo");
      return;
    }

    setMensaje("Vehiculo eliminado");
    cargarVehiculos();
  }

  useEffect(() => {
    if (token) cargarVehiculos();
  }, [token]);

  if (!token) {
    return (
      <main className="login-page">
        <section className="login-panel">
          <h1>Sistema de Parqueadero</h1>
          <p>Ingreso de operadores</p>

          <form onSubmit={login}>
            <label>
              Usuario
              <input value={usuario} onChange={(e) => setUsuario(e.target.value)} />
            </label>

            <label>
              Contrasena
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </label>

            <button type="submit">
              <LogIn size={18} />
              Entrar
            </button>
          </form>

          {mensaje && (
  <div className={`message ${mensaje.includes("invalidas") || mensaje.includes("No se") ? "error" : "success"}`}>
    {mensaje}
  </div>
)}
        </section>
      </main>
    );
  }

  return (
    <main className="app-page">
      <header className="topbar">
        <div>
          <h1>Parqueadero</h1>
          <p>Gestion de vehiculos registrados</p>
        </div>

        <button className="secondary" onClick={logout}>
          <LogOut size={18} />
          Salir
        </button>
      </header>

      <section className="content">
        <form className="vehicle-form" onSubmit={guardarVehiculo}>
          <h2>{editando ? "Editar vehiculo" : "Registrar vehiculo"}</h2>

          <label>
            Placa
            <input
              value={form.placa}
              disabled={Boolean(editando)}
              onChange={(e) => setForm({ ...form, placa: e.target.value.toUpperCase() })}
              required
            />
          </label>

          <label>
            Tipo
            <select value={form.tipo} onChange={(e) => setForm({ ...form, tipo: e.target.value })}>
              <option value="carro">Carro</option>
              <option value="moto">Moto</option>
              <option value="camioneta">Camioneta</option>
            </select>
          </label>

          <label>
            Estado
            <select
              value={form.estado}
              onChange={(e) => setForm({ ...form, estado: e.target.value })}
            >
              <option value="parqueado">Parqueado</option>
              <option value="retirado">Retirado</option>
            </select>
          </label>

          <button type="submit">
            {editando ? <Save size={18} /> : <Plus size={18} />}
            {editando ? "Guardar" : "Registrar"}
          </button>

          {editando && (
            <button
              type="button"
              className="secondary"
              onClick={() => {
                setEditando(null);
                setForm({ placa: "", tipo: "carro", estado: "parqueado" });
              }}
            >
              Cancelar
            </button>
          )}
        </form>

        <section className="table-panel">
          <div className="table-header">
            <h2>Vehiculos</h2>
            <button className="secondary" onClick={cargarVehiculos}>
              <RefreshCw size={18} />
              Actualizar
            </button>
          </div>

          {mensaje && <div className="message">{mensaje}</div>}

          <table>
            <thead>
              <tr>
                <th>Placa</th>
                <th>Tipo</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {vehiculos.map((vehiculo) => (
                <tr key={vehiculo.placa}>
                  <td>{vehiculo.placa}</td>
                  <td>{vehiculo.tipo}</td>
                  <td>
                    <span className={`status ${vehiculo.estado}`}>{vehiculo.estado}</span>
                  </td>
                  <td className="actions">
                    <button className="icon" onClick={() => editarVehiculo(vehiculo)}>
                      <Pencil size={17} />
                    </button>
                    <button className="icon danger" onClick={() => eliminarVehiculo(vehiculo.placa)}>
                      <Trash2 size={17} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </section>
    </main>
  );
}
