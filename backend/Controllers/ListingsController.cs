using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using StayIn.Api.Data;
using StayIn.Api.Models;
using StayIn.Api.DTOs;
using System.Security.Claims;

namespace StayIn.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ListingController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ListingController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/Listing/create
        [HttpPost("create")]
        // [Authorize] // ⚠️ Geçici olarak devre dışı - test için
        public async Task<IActionResult> CreateListing([FromBody] ListingDTO dto)
        {
            try
            {
                // ⚡ Kullanıcı ID'sini token'dan al (yoksa default 3 kullan - test için)
                int userId = 3; // ⚠️ Geçici default değer
                
                var userIdClaim = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                    ?? User.FindFirst("sub")?.Value
                    ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                    
                if (!string.IsNullOrEmpty(userIdClaim) && int.TryParse(userIdClaim, out int parsedUserId))
                {
                    userId = parsedUserId; // Token varsa onu kullan
                }

                var listing = new Listing
                {
                    UserId = userId, // ⚡ Kullanıcı ID'sini ata
                    PlaceType = dto.PlaceType,
                    AccommodationType = dto.AccommodationType,
                    Guests = dto.Guests,
                    Bedrooms = dto.Bedrooms,
                    Beds = dto.Beds,
                    Bathrooms = dto.Bathrooms,
                    Title = dto.Title,
                    Description = dto.Description,
                    Price = dto.Price,
                    AddressCountry = dto.AddressCountry,
                    AddressDistrict = dto.AddressDistrict,
                    AddressStreet = dto.AddressStreet,
                    AddressBuilding = dto.AddressBuilding,
                    AddressPostalCode = dto.AddressPostalCode,
                    AddressRegion = dto.AddressRegion,
                    AddressCity = dto.AddressCity,
                    Amenities = dto.Amenities,
                    PhotoUrls = dto.PhotoUrls,
                    Latitude = dto.Latitude,
                    Longitude = dto.Longitude,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Listings.Add(listing);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "İlan başarıyla yayınlandı!", listingId = listing.Id });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = $"İlan oluşturulamadı: {ex.Message}" });
            }
        }

        // GET: api/Listing/all
        [HttpGet("all")]
        public async Task<IActionResult> GetAllListings()
        {
            try
            {
                var listings = await _context.Listings
                    .OrderByDescending(l => l.CreatedAt)
                    .Select(l => new
                    {
                        l.Id,
                        l.Title,
                        l.Description,
                        l.PlaceType,
                        l.AccommodationType,
                        l.Guests,
                        l.Bedrooms,
                        l.Beds,
                        l.Bathrooms,
                        l.Price,
                        Address = new
                        {
                            l.AddressCountry,
                            l.AddressCity,
                            l.AddressDistrict,
                            l.AddressStreet,
                            l.AddressBuilding,
                            l.AddressPostalCode,
                            l.AddressRegion
                        },
                        l.Amenities,
                        l.PhotoUrls,
                        l.Latitude,
                        l.Longitude,
                        l.CreatedAt
                    })
                    .ToListAsync();

                return Ok(listings);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"İlanlar getirilemedi: {ex.Message}" });
            }
        }
    }
}