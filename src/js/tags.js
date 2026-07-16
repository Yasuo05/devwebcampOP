
(function () {
    const tagsInput = document.querySelector('#tags_input');

    if (tagsInput) {
        const tagsdiv = document.querySelector('#tags');
        const tagsInputHidden = document.querySelector('[name="tags"]');

        let tags = [];


        //recuperar del input oculto
        if (tagsInputHidden.value !=='') {
            tags=tagsInputHidden.value.split(',');
            mostrartags();
        }

        tagsInput.addEventListener('keypress', guardartag);

        function guardartag(e) {
            if (e.key === ',') {

                if (e.target.value.trim() === '' || e.target.value < 1) {
                    return
                }
                e.preventDefault();

                const tag = e.target.value.trim();
                if (tag) {
                    tags = [...tags, tag];
                    tagsInput.value = '';
                    console.log(tags);
                    mostrartags();
                }
            }
        }

        function mostrartags() {
            tagsdiv.textContent = '';
            tags.forEach(tag => {
                const etiqueta = document.createElement('LI');
                etiqueta.classList.add('formulario__tag');
                etiqueta.textContent = tag;
                etiqueta.ondblclick = eliminartag;
                tagsdiv.appendChild(etiqueta);
            })
            actualizarInputHidden();
        }

        function eliminartag(e) {
            e.target.remove();
            tags = tags.filter(tag => tag !== e.target.textContent);
            actualizarInputHidden();
        }


        function actualizarInputHidden() {
            tagsInputHidden.value = tags.toString();

        }

    }
})();
