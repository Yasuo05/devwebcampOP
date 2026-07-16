<main class="registro">
    <h2 class="registro__heading"><?php echo $titulo; ?></h2>
    <p class="registro__descripcion">Elige tu plan</p>

    <div class="paquetes__grid">
        <div class="paquete">
            <h3 class="paquete__nombre">Pase Gratis</h3>
            <ul class="paquete__lista">
                <li class="paquete__elemento">Acceso Virtual a DevWebCamp</li>
            </ul>

            <p class="paquete__precio">$0</p>

            <form method="POST" action="/finalizar-registro/gratis">
                <input class="paquetes__submit" type="submit" value="Inscripción Gratis">
            </form>
        </div>

        <div class="paquete">
            <h3 class="paquete__nombre">Pase Presencial</h3>
            <ul class="paquete__lista">
                <li class="paquete__elemento">Acceso Presencial a DevWebCamp</li>
                <li class="paquete__elemento">Pase por 2 días</li>
                <li class="paquete__elemento">Acceso a talleres y conferencias</li>
                <li class="paquete__elemento">Acceso a las grabaciones</li>
                <li class="paquete__elemento">Camisa del Evento</li>
                <li class="paquete__elemento">Comida y Bebida</li>
            </ul>

            <p class="paquete__precio">S/39</p>

            <div id="paypal-container-DZXPHHF4FZHXJ"></div>

        </div>

        <div class="paquete">
            <h3 class="paquete__nombre">Pase Virtual</h3>
            <ul class="paquete__lista">
                <li class="paquete__elemento">Acceso Virtual a DevWebCamp</li>
                <li class="paquete__elemento">Pase por 2 días</li>
                <li class="paquete__elemento">Acceso a talleres y conferencias</li>
                <li class="paquete__elemento">Acceso a las grabaciones</li>
            </ul>

            <p class="paquete__precio">S/9</p>

            <div id="paypal-container-DZXPHHF4FZHXJ"></div>

        </div>
    </div>
</main>








<script src="https://sandbox.paypal.com/sdk/js?client-id=BAAvwXYYFlVG6xCXhfs0P05n0T_0iytrqPRnctl-3M9Incip24OJ_YhSwe3LhXu2fi_EISdR8OGwXtuYiI&components=hosted-buttons&disable-funding=venmo&currency=USD"></script>
<script>
function initPayPalButton() {
  // Hosted Button Integration
  paypal.HostedButtons({
    hostedButtonId: "DZXPHHF4FZHXJ",
  }).render("#paypal-container-DZXPHHF4FZHXJ");

  // Regular PayPal Button Integration
  paypal.Buttons({
    style: {
      shape: 'rect',
      color: 'blue',
      layout: 'vertical',
      label: 'pay',
    },
    createOrder: function(data, actions) {
      return actions.order.create({
        purchase_units: [{"description":"1","amount":{"currency_code":"USD","value":30}}]
      });
    },
    onApprove: function(data, actions) {
      return actions.order.capture().then(function(orderData) {
        const datos = new FormData();
        datos.append('paquete_id', orderData.purchase_units[0].description);
        datos.append('pago_id', orderData.purchase_units[0].payments.captures[0].id);

        fetch('/finalizar-registro/pagar', {
          method: 'POST',
          body: datos
        })
        .then(respuesta => respuesta.json())
        .then(resultado => {
          if(resultado.resultado) {
            actions.redirect('http://localhost:3000/finalizar-registro/conferencias');
          }
        })
      });
    },
    onError: function(err) {
      console.log(err);
    }
  }).render('#paypal-button-container');

  // Virtual Pass PayPal Button
  paypal.Buttons({
    style: {
      shape: 'rect',
      color: 'blue',
      layout: 'vertical',
      label: 'pay',
    },
    createOrder: function(data, actions) {
      return actions.order.create({
        purchase_units: [{"description":"2","amount":{"currency_code":"USD","value":49}}]
      });
    },
    onApprove: function(data, actions) {
      return actions.order.capture().then(function(orderData) {
        const datos = new FormData();
        datos.append('paquete_id', orderData.purchase_units[0].description);
        datos.append('pago_id', orderData.purchase_units[0].payments.captures[0].id);

        fetch('/finalizar-registro/pagar', {
          method: 'POST',
          body: datos
        })
        .then(respuesta => respuesta.json())
        .then(resultado => {
          if(resultado.resultado) {
            actions.redirect('http://localhost:3000/finalizar-registro/conferencias');
          }
        })
      });
    },
    onError: function(err) {
      console.log(err);
    }
  }).render('#paypal-button-container-virtual');
}

initPayPalButton();
</script>
