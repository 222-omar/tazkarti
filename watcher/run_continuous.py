import time
import sys
import logging
from datetime import datetime
from watcher.watcher_service import WatcherService
from watcher.config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("tazkarti.runner")


def main():
    print("=" * 65)
    print(" 🇪🇬 رادار تذاكر مباريات الأهلي ومنتخب مصر (Tazkarti Alert Watcher)")
    print("=" * 65)
    print("📡 يتم فحص موقع تذكرتي كل 60 ثانية بشكل آلي ومستمر.")
    print("🔴 إشعار فوري لماتشات الأهلي -> topic: ahly_tickets")
    print("🇪🇬 إشعار فوري لماتشات مصر -> topic: egypt_tickets")
    print("اضغط Ctrl + C في أي وقت للإيقاف.")
    print("-" * 65)

    service = WatcherService()
    poll_interval = int(getattr(settings, "poll_interval_seconds", 60))

    while True:
        try:
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"\n🔍 [{now_str}] جاري فحص موقع تذكرتي الآن...")
            result = service.run_poll()

            total = result.get("total_matches", 0)
            tracked = result.get("tracked_matches", 0)
            notifications = result.get("notifications_sent", 0)
            seeded = result.get("seeded", False)

            if seeded:
                print(f"🌱 [تم التهيئة الأولى]: تم حفظ {total} مباراة بدون إرسال إشعارات قديمة.")
            else:
                print(f"✅ فحص سليم: تم العثور على {total} مباراة إجمالاً ({tracked} تخص الأهلي ومصر).")
                if notifications > 0:
                    print(f"🚀 تم إرسال {notifications} إشعار فوري للهواتف بنجاح!")
                else:
                    print("💤 لا توجد تغييرات جديدة في التذاكر أو الحالة.")

        except KeyboardInterrupt:
            print("\n🛑 تم إيقاف الرادار بواسطة المستخدم.")
            sys.exit(0)
        except Exception as exc:
            logger.error(f"خطأ أثناء الفحص: {exc}")

        print(f"⏳ الانتظار {poll_interval} ثانية للفحص التالي...")
        time.sleep(poll_interval)


if __name__ == "__main__":
    main()
