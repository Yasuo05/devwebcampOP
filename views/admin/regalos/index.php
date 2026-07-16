<h2 class="dashboard__heading"><?php echo $titulo; ?></h2>

<div class="dashboard__grafica">
  <canvas id="regalos-grafica" width="400" height="400"></canvas>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>
  const grafica = document.querySelector('#regalos-grafica');
  if (grafica) {

    obtenerDatos()
    async function obtenerDatos() {
      const url = '/api/regalos'
      const respuesta = await fetch(url)
      const resultado = await respuesta.json()
      const ctx = document.getElementById('regalos-grafica');

      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: resultado.map(regalo => regalo.nombre),
          datasets: [{
            label: '',
            backgroundColor: [
              '#f97316', // Naranja claro
              '#a3e635', // Verde lima claro
              '#38e1ff', // Celeste claro
              '#c084fc', // Morado pastel claro
              '#f87171', // Rojo rosado claro
              '#2dd4bf', // Turquesa claro
              '#f43f8c', // Rosa claro
              '#fb7185', // Rosa intenso claro
              '#a78bfa',
            ],
            
            data: resultado.map(regalo => regalo.total),
          }]
        },
        options: {
          scales: {
            y: {
              beginAtZero: true
            }
          },
          plugins: {
            legend: {
              display: false
            }
          }
        }
      });
    }
  }
</script>