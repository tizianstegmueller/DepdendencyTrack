using Microsoft.EntityFrameworkCore;
using ShopAPI.Models;

namespace ShopAPI.Data;

public class ShopContext : DbContext
{
    public ShopContext(DbContextOptions<ShopContext> options) : base(options)
    {
    }

    public DbSet<Product> Products { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Seed-Daten für die InMemory-Datenbank
        modelBuilder.Entity<Product>().HasData(
            new Product
            {
                Id = 1,
                Name = "Laptop",
                Description = "Hochleistungs-Laptop für professionelle Anwendungen",
                Price = 1299.99m,
                ImageUrl = "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400",
                Stock = 15
            },
            new Product
            {
                Id = 2,
                Name = "Smartphone",
                Description = "Neuestes Smartphone mit 5G-Unterstützung",
                Price = 899.99m,
                ImageUrl = "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400",
                Stock = 30
            },
            new Product
            {
                Id = 3,
                Name = "Kopfhörer",
                Description = "Kabellose Bluetooth-Kopfhörer mit Noise-Cancelling",
                Price = 199.99m,
                ImageUrl = "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400",
                Stock = 50
            },
            new Product
            {
                Id = 4,
                Name = "Tastatur",
                Description = "Mechanische Gaming-Tastatur mit RGB-Beleuchtung",
                Price = 129.99m,
                ImageUrl = "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400",
                Stock = 25
            },
            new Product
            {
                Id = 5,
                Name = "Maus",
                Description = "Ergonomische Wireless-Maus für produktives Arbeiten",
                Price = 49.99m,
                ImageUrl = "https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400",
                Stock = 40
            },
            new Product
            {
                Id = 6,
                Name = "Monitor",
                Description = "27 Zoll 4K-Monitor mit HDR-Unterstützung",
                Price = 549.99m,
                ImageUrl = "https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=400",
                Stock = 12
            }
        );
    }
}
