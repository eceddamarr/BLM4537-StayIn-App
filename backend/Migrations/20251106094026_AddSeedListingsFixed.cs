using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace StayinApi.Migrations
{
    /// <inheritdoc />
    public partial class AddSeedListingsFixed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Listings",
                columns: new[] { "Id", "AccommodationType", "AddressBuilding", "AddressCity", "AddressCountry", "AddressDistrict", "AddressPostalCode", "AddressRegion", "AddressStreet", "Amenities", "Bathrooms", "Bedrooms", "Beds", "CreatedAt", "Description", "Guests", "Latitude", "Longitude", "PhotoUrls", "PlaceType", "Price", "Title" },
                values: new object[,]
                {
                    { 1, "Bütün mekan", "A Blok Kat:3", "İzmir", "Türkiye", "Çeşme", "35930", "Ege", "Alaçatı Mahallesi, Sahil Caddesi No:45", "[\"Wifi\",\"Klima\",\"Havuz\",\"Jakuzi\",\"Deniz Manzaras\\u0131\",\"\\u00D6zel Plaj\"]", 1, 2, 2, new DateTime(2024, 11, 1, 10, 0, 0, 0, DateTimeKind.Utc), "Çeşme'nin en güzel sahilinde, deniz manzaralı modern daire. Havuz, jakuzi ve özel plaj erişimi mevcut.", 4, 38.322800000000001, 26.302499999999998, "[]", "Daire", 2500m, "Deniz Manzaralı Lüks Daire" },
                    { 2, "Bütün mekan", "Villa", "Antalya", "Türkiye", "Kalkan", "07960", "Akdeniz", "Kalamar Mahallesi, Yalı Sokak No:12", "[\"Wifi\",\"Klima\",\"Havuz\",\"Bah\\u00E7e\",\"Mangal\",\"Deniz Manzaras\\u0131\",\"\\u00D6zel Otopark\"]", 3, 4, 5, new DateTime(2024, 11, 3, 14, 30, 0, 0, DateTimeKind.Utc), "Kalkan'da özel havuzlu, geniş bahçeli lüks villa. Muhteşem deniz manzarası ve sessiz konum.", 8, 36.265599999999999, 29.408899999999999, "[]", "Villa", 5000m, "Modern Villa Havuz ve Bahçe" },
                    { 3, "Bütün mekan", "Butik Otel", "Muğla", "Türkiye", "Bodrum", "48400", "Ege", "Gümbet Mahallesi, Plaj Yolu No:8", "[\"Wifi\",\"Klima\",\"TV\",\"Kahvalt\\u0131\",\"Plaja Yak\\u0131n\",\"Restoran\"]", 2, 3, 3, new DateTime(2024, 11, 4, 9, 15, 0, 0, DateTimeKind.Utc), "Bodrum'un kalbinde, plaja yürüme mesafesinde modern ve konforlu konaklama. Kahvaltı dahil.", 6, 37.034399999999998, 27.430499999999999, "[]", "Ev", 3200m, "Plaja Sıfır Butik Otel" },
                    { 4, "Bütün mekan", "Bungalov 5", "Bolu", "Türkiye", "Abant", "14100", "Karadeniz", "Göl Mahallesi, Doğa Yolu No:23", "[\"Wifi\",\"\\u015E\\u00F6mine\",\"Veranda\",\"G\\u00F6l Manzaras\\u0131\",\"Do\\u011Fa\",\"Mangal\"]", 1, 1, 2, new DateTime(2024, 11, 5, 16, 45, 0, 0, DateTimeKind.Utc), "Abant Gölü manzaralı, doğa ile iç içe huzurlu bungalov. Şömine, veranda ve orman manzarası.", 3, 40.616700000000002, 31.2667, "[]", "Kulübe", 1800m, "Doğa İçinde Bungalov" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 4);
        }
    }
}
