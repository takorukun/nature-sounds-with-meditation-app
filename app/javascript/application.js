import "@hotwired/turbo-rails"
import "./controllers/application.js";
import "./controllers/hello_controller.js";
import "./controllers/index.js";
import Rails from "@rails/ujs"
Rails.start()

//shared/transition-opacity_bg-images
document.addEventListener('turbo:load', function() {
  if (document.getElementById('main-bg1')) {
    let image1Visible = true;

    setInterval(function() {

      document.querySelectorAll('.image-set').forEach(function(imageSet) {
        const bg1Id = imageSet.getAttribute('data-bg1');
        const bg2Id = imageSet.getAttribute('data-bg2');

        console.log(bg1Id, bg2Id);

        if (image1Visible) {
          document.getElementById(bg1Id).style.opacity = '0';
          document.getElementById(bg2Id).style.opacity = '1';
        } else {
          document.getElementById(bg1Id).style.opacity = '1';
          document.getElementById(bg2Id).style.opacity = '0';
        }
      });
      
      image1Visible = !image1Visible;
    }, 5000);
  }

//shared/main-text-content
  if (document.getElementById('bg1_bonfire_sounds_image1')) {
    const bgImages = document.querySelectorAll('.main-bg-image');
    const textElements = document.querySelectorAll('.max-w-md h1, .max-w-md p, .max-w-md button');
    
    const textColors = [
      'text-neutral-950',
      'text-red-950',
      'text-green-950',
      'text-indigo-950',
      'text-violet-950',
      'text-fuchsia-950'
    ];

    let currentIndex = 0;

    setInterval(function() {
      bgImages[currentIndex].style.opacity = '0';

      textElements.forEach(el => el.style.opacity = '0');

      setTimeout(function() {
        textElements.forEach(el => {
          textColors.forEach(color => el.classList.remove(color));
          el.classList.add(textColors[currentIndex]);
          el.style.opacity = '1';
        });
      }, 2000);

      currentIndex = (currentIndex + 1) % bgImages.length;

      bgImages[currentIndex].style.opacity = '1';

    }, 10000);
  }
});

//users/show
document.addEventListener("turbo:load", function() {
  
  window.showModal = function(day) {
    const modalId = 'modal-' + day;
    const modal = document.getElementById(modalId);
    modal.showModal();
  }
});

