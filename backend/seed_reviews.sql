-- Test için rezervasyonlar ve yorumlar ekleyelim

-- Tamamlanmış rezervasyonlar ekle (geçmiş tarihler)
INSERT INTO Reservations (ListingId, GuestId, HostId, CheckInDate, CheckOutDate, Guests, TotalPrice, Status, CreatedAt, ResponsedAt)
VALUES 
(1, 2, 1, '2024-10-01 14:00:00', '2024-10-05 11:00:00', 2, 10000, 'Approved', '2024-09-25 10:00:00', '2024-09-25 15:00:00'),
(2, 3, 1, '2024-10-10 14:00:00', '2024-10-15 11:00:00', 6, 25000, 'Approved', '2024-10-01 09:00:00', '2024-10-01 12:00:00'),
(3, 4, 2, '2024-10-20 14:00:00', '2024-10-23 11:00:00', 4, 9600, 'Approved', '2024-10-15 08:00:00', '2024-10-15 14:00:00'),
(6, 5, 3, '2024-11-01 14:00:00', '2024-11-03 11:00:00', 2, 7000, 'Approved', '2024-10-25 10:00:00', '2024-10-25 16:00:00'),
(7, 1, 3, '2024-11-05 14:00:00', '2024-11-10 11:00:00', 8, 32500, 'Approved', '2024-10-28 11:00:00', '2024-10-28 17:00:00'),
(30, 2, 3, '2024-09-15 14:00:00', '2024-09-20 11:00:00', 6, 22500, 'Approved', '2024-09-01 10:00:00', '2024-09-01 14:00:00'),
(30, 3, 3, '2024-08-10 14:00:00', '2024-08-15 11:00:00', 8, 22500, 'Approved', '2024-07-25 09:00:00', '2024-07-25 12:00:00'),
(30, 4, 3, '2024-07-20 14:00:00', '2024-07-25 11:00:00', 7, 22500, 'Approved', '2024-07-05 11:00:00', '2024-07-05 15:00:00'),
(30, 5, 3, '2024-10-05 14:00:00', '2024-10-10 11:00:00', 6, 22500, 'Approved', '2024-09-20 08:00:00', '2024-09-20 13:00:00'),
(30, 1, 3, '2024-11-12 14:00:00', '2024-11-17 11:00:00', 8, 22500, 'Approved', '2024-10-30 10:00:00', '2024-10-30 16:00:00');

-- Yorumları ekle
INSERT INTO Reviews (ListingId, GuestId, ReservationId, Rating, Comment, CreatedAt)
VALUES 
(1, 2, (SELECT Id FROM Reservations WHERE ListingId = 1 AND GuestId = 2 LIMIT 1), 5, 'Harika bir deneyimdi! Deniz manzarası muhteşem, ev tertemiz ve konforlu. Ev sahibi çok yardımcı oldu. Kesinlikte tekrar geleceğiz.', '2024-10-06 15:30:00'),
(2, 3, (SELECT Id FROM Reservations WHERE ListingId = 2 AND GuestId = 3 LIMIT 1), 5, 'Mükemmel bir villa! Havuz çok güzeldi, çocuklar bayıldı. Kalkan''ın en güzel yerlerinden birinde konumlanmış. Ailecek harika zaman geçirdik.', '2024-10-16 10:00:00'),
(3, 4, (SELECT Id FROM Reservations WHERE ListingId = 3 AND GuestId = 4 LIMIT 1), 4, 'Genel olarak güzel bir konaklama deneyimiydi. Plaja çok yakın olması büyük avantaj. Sadece wifi biraz yavaştı ama genel olarak memnun kaldık.', '2024-10-24 09:15:00'),
(6, 5, (SELECT Id FROM Reservations WHERE ListingId = 6 AND GuestId = 5 LIMIT 1), 5, 'Boğaz manzarası gerçekten efsane! Suit çok lüks ve konforlu. Spa hizmeti harika. Romantik bir kaçamak için ideal.', '2024-11-04 14:45:00'),
(7, 1, (SELECT Id FROM Reservations WHERE ListingId = 7 AND GuestId = 1 LIMIT 1), 5, 'Kaş''ın incisi! Sonsuzluk havuzundan gün batımı izlemek paha biçilemez. Villa son derece geniş ve şık. Grup tatili için mükemmel.', '2024-11-11 16:20:00'),
(30, 2, (SELECT Id FROM Reservations WHERE ListingId = 30 AND GuestId = 2 LIMIT 1), 5, 'Sarıyer''in en güzel villarından biri! Havuz harika, Ladies Beach''e çok yakın. Bahçe çok bakımlı ve geniş. Ailecek muhteşem bir tatil geçirdik, teşekkürler!', '2024-09-21 10:30:00'),
(30, 3, (SELECT Id FROM Reservations WHERE ListingId = 30 AND GuestId = 3 ORDER BY CreatedAt LIMIT 1), 5, 'Mükemmel bir lokasyon ve villa! Her şey düşünülmüş, mutfak tam donanımlı. Çocuklar havuzdan çıkmak bilmedi. Ev sahibi çok ilgili ve yardımcı. 10 üzerinden 10!', '2024-08-16 14:15:00'),
(30, 4, (SELECT Id FROM Reservations WHERE ListingId = 30 AND GuestId = 4 LIMIT 1), 4, 'Çok güzel bir villa, temiz ve ferah. Sadece klimalardan biri biraz gürültülüydü ama genel olarak çok memnun kaldık. Konumu harika, denize yakın ve sessiz.', '2024-07-26 11:45:00'),
(30, 5, (SELECT Id FROM Reservations WHERE ListingId = 30 AND GuestId = 5 LIMIT 1), 5, 'Harika bir deneyim! Villa fotoğraflardan daha güzel çıktı. Havuz temiz, bahçe bakımlı, odalar geniş. Arkadaşlarla gelmiştik, herkes çok mutluydu. Kesinlikle tavsiye ederim.', '2024-10-11 16:00:00'),
(30, 1, (SELECT Id FROM Reservations WHERE ListingId = 30 AND GuestId = 1 ORDER BY CreatedAt DESC LIMIT 1), 4, 'Güzel bir villa, konumu ideal. Havuz ve bahçe çok güzel. Tek eksi mutfakta bazı malzemeler eksikti ama genel olarak harika bir tatildi. Tekrar geliriz.', '2024-11-18 09:30:00');