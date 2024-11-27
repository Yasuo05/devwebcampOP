<main class="devwebcamp">
    <h2 class="devwebcamp__heading"> <?php echo $titulo; ?></h2>
    <p class="devwebcamp__descripcion">Conoce la conferencia más imporantes de la Asociación New Vinedos </p>

    <div <?php aos_animacion(); ?>  class="devwebcamp__grid">
        <div class="devwebcamp__imagen">
            <picture>
                <source srcset="build/img/sobre_devwebcamp.avif" type="image/avif">
                <source srcset="build/img/sobre_devwebcamp.webp" type="image/webp">
                <img loading="lazy" width="200" height="300" src="build/img/sobre_devwebcamp.">
            </picture>
        </div>

        <div <?php aos_animacion(); ?> class="devwebcamp__contenido">
            <p  class="devwebcamp__texto">La asociación E.T.P. New Vinedos es un grupo conformado por aproximadamente 40 mototaxistas que surgió con el objetivo de mejorar las condiciones laborales y fomentar el apoyo mutuo entre sus miembros. Antes de su creación, cada conductor operaba de manera independiente, enfrentando numerosos desafíos como la falta de paraderos fijos y el riesgo económico ante imprevistos.
            </p>
            <p class="devwebcamp__texto">Actualmente, E.T.P. New Vinedos se distingue por su organización y visión estratégica. Celebran reuniones regulares donde coordinan medidas, revisan responsabilidades y trazan metas conjuntas que benefician tanto a sus integrantes como a los pasajeros. Esta estructura ha permitido consolidar un entorno laboral más seguro, organizado y sostenible, promoviendo el crecimiento del gremio y posicionándolo como una opción confiable y accesible en el sector del transporte local.
            </p>

            </p>
        </div>
    </div>
</main>