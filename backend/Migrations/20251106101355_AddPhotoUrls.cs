using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StayinApi.Migrations
{
    /// <inheritdoc />
    public partial class AddPhotoUrls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 1,
                column: "PhotoUrls",
                value: "[\"https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800\",\"https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800\"]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 2,
                column: "PhotoUrls",
                value: "[\"https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800\",\"https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800\"]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 3,
                column: "PhotoUrls",
                value: "[\"https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800\",\"https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=800\"]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 4,
                column: "PhotoUrls",
                value: "[\"https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800\",\"https://images.unsplash.com/photo-1542718610-a1d656d1884c?w=800\"]");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 1,
                column: "PhotoUrls",
                value: "[]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 2,
                column: "PhotoUrls",
                value: "[]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 3,
                column: "PhotoUrls",
                value: "[]");

            migrationBuilder.UpdateData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 4,
                column: "PhotoUrls",
                value: "[]");
        }
    }
}
