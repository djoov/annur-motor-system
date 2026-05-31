export const SITE_CONFIG = {
    name: "Annur Motor",
    description: "Toko Spare Part Motor Terpercaya di Magelang",
    whatsapp: {
        number: "6281287562914",
        defaultMessage: "Halo Annur Motor, saya ingin bertanya...",
        getLink() {
            return `https://wa.me/${this.number}?text=${encodeURIComponent(this.defaultMessage)}`;
        }
    },
    contact: {
        address: "Jl. Raya Pucang No. 12, Karang Wetan, Pucang, Secang, Kabupaten Magelang, Jawa Tengah",
        email: "annurmotorpucang@gmail.com",
        mapUrl: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3955.51739055933!2d110.2520110747618!3d-7.518600892487531!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x2e7a8693aee2065f%3A0xfb90c5a96cf4c97a!2sToko%20Sparepart%20-%20Annur%20Motor!5e0!3m2!1sen!2sid!4v1722072919374!5m2!1sen!2sid",
        hours: {
            weekdays: "Senin - Sabtu: 07:30 - 17:00",
            sunday: "Minggu: 08:00 - 17:00"
        }
    }
};
