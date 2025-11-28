import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard এর জন্য
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MotivationPage extends StatefulWidget {
  const MotivationPage({super.key});

  @override
  // Return the public State type to avoid exposing a private type in the
  // public API signature.
  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  // This list doesn't change at runtime so mark it final.
  final List<Map<String, String>> _speeches = [
    {
      "category": "Success",
      "speech":
          "Success doesn’t come from what you do occasionally, it comes from what you do consistently.",
    },
    {"category": "Religion", "speech": "Allah, the Best of Planners."},
    {
      "category": "Hard Work",
      "speech":
          "There is no substitute for hard work. Great things never come from comfort zones.",
    },
    {
      "category": "Perseverance",
      "speech":
          "It does not matter how slowly you go as long as you do not stop.",
    },
    {
      "category": "Courage",
      "speech": "Courage is not the absence of fear, but the triumph over it.",
    },
    {
      "category": "Motivation",
      "speech":
          "The future belongs to those who believe in the beauty of their dreams.",
    },
    {
      "category": "Determination",
      "speech":
          "The difference between the impossible and the possible lies in a person’s determination.",
    },
    {
      "category": "Focus",
      "speech":
          "Focus on your goals, not your fears. Focus like a laser beam on your goals.",
    },
    {
      "category": "Attitude",
      "speech":
          "Your attitude, not your aptitude, will determine your altitude.",
    },
    {
      "category": "Dreams",
      "speech": "Don’t watch the clock; do what it does. Keep going.",
    },
    {"category": "Resilience", "speech": "Fall seven times, stand up eight."},
    {
      "category": "Inspiration",
      "speech": "The only way to do great work is to love what you do.",
    },
    {
      "category": "Leadership",
      "speech":
          "A leader is one who knows the way, goes the way, and shows the way.",
    },
    {
      "category": "Self-Belief",
      "speech": "Believe you can and you’re halfway there.",
    },
    {
      "category": "Change",
      "speech": "Change your thoughts and you change your world.",
    },
    {
      "category": "Optimism",
      "speech":
          "Keep your face always toward the sunshine—and shadows will fall behind you.",
    },
    {
      "category": "Gratitude",
      "speech": "Gratitude turns what we have into enough.",
    },
    {
      "category": "Mindset",
      "speech":
          "Whether you think you can or you think you can’t, you’re right.",
    },
    {
      "category": "Learning",
      "speech":
          "Live as if you were to die tomorrow. Learn as if you were to live forever.",
    },
    {
      "category": "Courage",
      "speech":
          "Courage is resistance to fear, mastery of fear—not absence of fear.",
    },
    {
      "category": "Perseverance",
      "speech": "It always seems impossible until it’s done.",
    },
    {
      "category": "Success",
      "speech": "Don’t be afraid to give up the good to go for the great.",
    },
    {
      "category": "Motivation",
      "speech":
          "The harder you work for something, the greater you’ll feel when you achieve it.",
    },
    {"category": "Determination", "speech": "Dream big and dare to fail."},
    {
      "category": "Focus",
      "speech": "Success is not in what you have, but who you are.",
    },
    {
      "category": "Attitude",
      "speech":
          "A positive attitude causes a chain reaction of positive thoughts, events, and outcomes.",
    },
    {
      "category": "Dreams",
      "speech":
          "The only limit to our realization of tomorrow will be our doubts of today.",
    },
    {
      "category": "Resilience",
      "speech":
          "Strength does not come from physical capacity. It comes from an indomitable will.",
    },
    {
      "category": "Inspiration",
      "speech": "The best way to predict the future is to create it.",
    },
    {
      "category": "Leadership",
      "speech":
          "The function of leadership is to produce more leaders, not more followers.",
    },
    {
      "category": "Self-Belief",
      "speech":
          "You are never too old to set another goal or to dream a new dream.",
    },
    {
      "category": "Change",
      "speech": "To improve is to change; to be perfect is to change often.",
    },
    {
      "category": "Optimism",
      "speech": "Stay positive, work hard, make it happen.",
    },
    {
      "category": "Gratitude",
      "speech":
          "Gratitude is not only the greatest of virtues but the parent of all others.",
    },
    {
      "category": "Mindset",
      "speech": "The mind is everything. What you think you become.",
    },
    {
      "category": "Learning",
      "speech": "An investment in knowledge pays the best interest.",
    },
    {
      "category": "Courage",
      "speech":
          "You gain strength, courage, and confidence by every experience in which you really stop to look fear in the face.",
    },
    {
      "category": "Perseverance",
      "speech":
          "Success is not final, failure is not fatal: It is the courage to continue that counts.",
    },
    {
      "category": "Success",
      "speech":
          "The secret of success is to do the common thing uncommonly well.",
    },
    {
      "category": "Motivation",
      "speech": "Don’t limit your challenges. Challenge your limits.",
    },
    {
      "category": "Determination",
      "speech":
          "What you get by achieving your goals is not as important as what you become by achieving your goals.",
    },
    {
      "category": "Focus",
      "speech":
          "The successful warrior is the average man, with laser-like focus.",
    },
    {
      "category": "Attitude",
      "speech": "Your attitude determines your direction.",
    },
    {"category": "Dreams", "speech": "If you can dream it, you can do it."},
    {
      "category": "Resilience",
      "speech":
          "The greatest glory in living lies not in never falling, but in rising every time we fall.",
    },
    {
      "category": "Inspiration",
      "speech": "Act as if what you do makes a difference. It does.",
    },
    {
      "category": "Leadership",
      "speech": "Leadership is the capacity to translate vision into reality.",
    },
    {
      "category": "Self-Belief",
      "speech":
          "You are braver than you believe, stronger than you seem, and smarter than you think.",
    },
    {
      "category": "Change",
      "speech":
          "The only way to make sense out of change is to plunge into it, move with it, and join the dance.",
    },
    {
      "category": "Optimism",
      "speech": "Keep your eyes on the stars, and your feet on the ground.",
    },
    {
      "category": "Gratitude",
      "speech": "Gratitude is the fairest blossom which springs from the soul.",
    },
    {
      "category": "Mindset",
      "speech":
          "A strong positive mental attitude will create more miracles than any wonder drug.",
    },
    {
      "category": "Learning",
      "speech":
          "Education is the most powerful weapon which you can use to change the world.",
    },
    {
      "category": "Courage",
      "speech": "It takes courage to grow up and become who you really are.",
    },
    {
      "category": "Perseverance",
      "speech": "The harder the conflict, the greater the triumph.",
    },
    {"category": "Success", "speech": "Don’t wait for opportunity. Create it."},
    {
      "category": "Motivation",
      "speech": "Great things never come from comfort zones.",
    },
    {
      "category": "Determination",
      "speech":
          "The future belongs to those who believe in the beauty of their dreams.",
    },
    {
      "category": "Focus",
      "speech":
          "Success usually comes to those who are too busy to be looking for it.",
    },
    {
      "category": "Attitude",
      "speech":
          "A bad attitude is like a flat tire. You can’t go anywhere until you change it.",
    },
    {
      "category": "Dreams",
      "speech":
          "You are never too old to set another goal or to dream a new dream.",
    },
    {
      "category": "Resilience",
      "speech":
          "Do not judge me by my success, judge me by how many times I fell down and got back up again.",
    },
    {
      "category": "Inspiration",
      "speech":
          "What lies behind us and what lies before us are tiny matters compared to what lies within us.",
    },
    {
      "category": "Leadership",
      "speech":
          "The challenge of leadership is to be strong, but not rude; be kind, but not weak; be bold, but not a bully; be thoughtful, but not lazy; be humble, but not timid; be proud, but not arrogant; have humor, but without folly.",
    },
    {
      "category": "Self-Belief",
      "speech":
          "The only person you are destined to become is the person you decide to be.",
    },
    {
      "category": "Change",
      "speech":
          "Your life does not get better by chance, it gets better by change.",
    },
    {
      "category": "Optimism",
      "speech": "Positive anything is better than negative nothing.",
    },
    {
      "category": "Gratitude",
      "speech":
          "Gratitude unlocks the fullness of life. It turns what we have into enough, and more.",
    },
    {
      "category": "Mindset",
      "speech":
          "The only limit to our realization of tomorrow will be our doubts of today.",
    },
    {
      "category": "Learning",
      "speech":
          "The beautiful thing about learning is that no one can take it away from you.",
    },
    {"category": "Courage", "speech": "Courage is grace under pressure."},
    {
      "category": "Perseverance",
      "speech": "Energy and persistence conquer all things.",
    },
    {
      "category": "Success",
      "speech": "The way to get started is to quit talking and begin doing.",
    },
    {
      "category": "Motivation",
      "speech": "Don’t watch the clock; do what it does. Keep going.",
    },
    {
      "category": "Determination",
      "speech": "You miss 100% of the shots you don’t take.",
    },
    {
      "category": "Focus",
      "speech":
          "The successful person has the habit of doing the things failures don’t like to do.",
    },
    {
      "category": "Attitude",
      "speech":
          "We cannot change our past. We can not change the fact that people act in a certain way. We can not change the inevitable. The only thing we can do is play on the one string we have, and that is our attitude.",
    },
    {
      "category": "Dreams",
      "speech":
          "All our dreams can come true, if we have the courage to pursue them.",
    },
    {
      "category": "Resilience",
      "speech":
          "It’s not whether you get knocked down, it’s whether you get up.",
    },
    {
      "category": "Inspiration",
      "speech":
          "The only limit to your impact is your imagination and commitment.",
    },
    {
      "category": "Leadership",
      "speech": "Innovation distinguishes between a leader and a follower.",
    },
    {
      "category": "Self-Belief",
      "speech": "Act as if what you do makes a difference. It does.",
    },
    {
      "category": "Change",
      "speech":
          "Progress is impossible without change, and those who cannot change their minds cannot change anything.",
    },
    {
      "category": "Optimism",
      "speech":
          "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.",
    },
    {
      "category": "Gratitude",
      "speech":
          "When I started counting my blessings, my whole life turned around.",
    },
    {
      "category": "Mindset",
      "speech":
          "Whether you think you can or you think you can’t, you’re right.",
    },
    {
      "category": "Learning",
      "speech":
          "The more that you read, the more things you will know. The more that you learn, the more places you’ll go.",
    },
    {
      "category": "Courage",
      "speech":
          "Courage is the most important of all the virtues because, without courage, you can’t practice any other virtue consistently.",
    },
    {
      "category": "Perseverance",
      "speech":
          "Never give up on a dream just because of the time it will take to accomplish it. The time will pass anyway.",
    },
    {
      "category": "Success",
      "speech":
          "Success is not how high you have climbed, but how you make a positive difference to the world.",
    },
    {
      "category": "Motivation",
      "speech":
          "The only place where success comes before work is in the dictionary.",
    },
    {
      "category": "Determination",
      "speech":
          "You don’t have to be great to start, but you have to start to be great.",
    },
    {
      "category": "Focus",
      "speech":
          "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.",
    },
    {
      "category": "Attitude",
      "speech":
          "The greatest discovery of all time is that a person can change his future by merely changing his attitude.",
    },
    {"category": "Dreams", "speech": "Dream big. Start small. Act now."},
    // {
    //   "category": "Resilience",
    //   "speech":
    //       "Resilience is knowing that you are the only one that has the power and the responsibility to pick yourself up.",
    // },
    // {
    //   "category": "Inspiration",
    //   "speech": "The best revenge is massive success.",
    // },
    // {
    //   "category": "Leadership",
    //   "speech":
    //       "Do what you feel in your heart to be right – for you’ll be criticized anyway.",
    // },
    // {
    //   "category": "Self-Belief",
    //   "speech":
    //       "Believe in yourself and all that you are. Know that there is something inside you that is greater than any obstacle.",
    // },
    // {
    //   "category": "Change",
    //   "speech":
    //       "Embrace uncertainty. Some of the most beautiful chapters in our lives won’t have a title until much later.",
    // },
    {
      "category": "Optimism",
      "speech": "Stay positive, work hard, make it happen.",
    },
    // ... আপনার অন্যান্য speeches এখানে রাখুন
  ];

  // Note: adding new speeches via UI has been disabled per UX request.

  // Persisted map of english speech -> bangla meaning
  Map<String, String> _meanings = {};

  @override
  void initState() {
    super.initState();
    _loadMeanings();
  }

  Future<void> _loadMeanings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('bangla_meanings');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        setState(() {
          _meanings = decoded.map((k, v) => MapEntry(k, v.toString()));
        });
      } catch (_) {}
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Speech"),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView.builder(
        itemCount: _speeches.length,
        itemBuilder: (context, index) {
          // Show each speech; expansion reveals Bangla meaning if available
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb, color: Colors.deepOrange),
              title: Text(
                _speeches[index]["category"]!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_speeches[index]["speech"]!),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bangla meaning:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      // Simple mapping for a few translations; fallback message otherwise
                      Text(
                        _meanings[_speeches[index]["speech"]!] ??
                            _banglaMeaningFor(_speeches[index]["speech"]!) ??
                            'বাংলা মানে যোগ করা হয়নি।',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final text = _speeches[index]["speech"]!;
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied English to clipboard!"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy English'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              final key = _speeches[index]["speech"]!;
                              final bangla =
                                  _meanings[key] ?? _banglaMeaningFor(key);
                              if (bangla == null || bangla.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'কোনো বাংলা অনুবাদ পাওয়া যায়নি।',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Clipboard.setData(ClipboardData(text: bangla));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bangla copied to clipboard!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_all),
                            label: const Text('Copy Bangla'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // add button intentionally removed
    );
  }

  // A tiny lookup of some Bangla meanings for selected English speeches.
  // Expand as needed. Returns null when no translation is available.
  String? _banglaMeaningFor(String english) {
    final map = {
      "Success doesn’t come from what you do occasionally, it comes from what you do consistently.":
          "সাফল্য আসে আপনার পরপর কাজ থেকে, কদাচিৎ করা কাজ থেকে নয়।",
      "Allah, the Best of Planners.": "আল্লাহ, সর্বোত্তম পরিকল্পনাকারী।",

      "There is no substitute for hard work. Great things never come from comfort zones.":
          "পরিশ্রমের কোনো বিকল্প নেই। মহান কিছু কখনোই আরামের জায়গা থেকে আসে না।",

      "It does not matter how slowly you go as long as you do not stop.":
          "তুমি কত ধীরে যাচ্ছো তা গুরুত্বপূর্ণ নয়, যতক্ষণ না তুমি থেমে যাচ্ছো।",

      "Courage is not the absence of fear, but the triumph over it.":
          "সাহস মানে ভয় না থাকা নয়, বরং ভয়কে জয় করা।",

      "The future belongs to those who believe in the beauty of their dreams.":
          "ভবিষ্যৎ তাদেরই, যারা তাদের স্বপ্নের সৌন্দর্যে বিশ্বাস রাখে।",

      "The difference between the impossible and the possible lies in a person’s determination.":
          "অসম্ভব ও সম্ভবের পার্থক্য একজন মানুষের দৃঢ় সংকল্পে নিহিত।",

      "Focus on your goals, not your fears. Focus like a laser beam on your goals.":
          "তোমার ভয় নয়, লক্ষ্যেই মনোনিবেশ করো। লক্ষ্যভেদী লেজার বিমের মতো মনোযোগ দাও।",

      "Your attitude, not your aptitude, will determine your altitude.":
          "তোমার উচ্চতা নির্ধারণ করবে তোমার মনোভাব, তোমার দক্ষতা নয়।",

      "Don’t watch the clock; do what it does. Keep going.":
          "ঘড়ির দিকে তাকিও না; যা করে সেটাই করো। চলতে থাকো।",

      "Fall seven times, stand up eight.":
          "সাতবার পড়ে যাও, আটবার উঠে দাঁড়াও।",

      "The only way to do great work is to love what you do.":
          "মহান কাজ করার একমাত্র উপায় হলো যা করছো তা ভালোবাসা।",

      "A leader is one who knows the way, goes the way, and shows the way.":
          "একজন নেতা সেই, যে পথ জানে, পথে চলে এবং অন্যদের সেই পথ দেখায়।",

      "Believe you can and you’re halfway there.":
          "বিশ্বাস রাখো তুমি পারবে — তাতেই তুমি অর্ধেক পথ পেরিয়ে গেছো।",

      "Change your thoughts and you change your world.":
          "তোমার চিন্তা বদলাও, তোমার পৃথিবী বদলে যাবে।",

      "Keep your face always toward the sunshine—and shadows will fall behind you.":
          "সবসময় সূর্যের দিকে মুখ রাখো — আর ছায়া তোমার পেছনে পড়ে থাকবে।",

      "Gratitude turns what we have into enough.":
          "কৃতজ্ঞতা আমাদের যা আছে তাই যথেষ্ট করে তোলে।",

      "Whether you think you can or you think you can’t, you’re right.":
          "তুমি ভাবো পারবে বা ভাবো পারবে না — দুটোই ঠিক, কারণ তা তোমার চিন্তার উপর নির্ভর করে।",

      "Live as if you were to die tomorrow. Learn as if you were to live forever.":
          "এমনভাবে বাঁচো যেন কালই মারা যাবে, এমনভাবে শিখো যেন চিরকাল বাঁচবে।",

      "Courage is resistance to fear, mastery of fear—not absence of fear.":
          "সাহস মানে ভয়কে প্রতিহত করা, ভয়কে নিয়ন্ত্রণ করা — ভয় না থাকা নয়।",

      "It always seems impossible until it’s done.":
          "কোনো কিছু অসম্ভব মনে হয় যতক্ষণ না সেটা সম্পন্ন হয়।",

      "Don’t be afraid to give up the good to go for the great.":
          "ভালো কিছু ছাড়তে ভয় পেও না, আরও ভালো কিছুর জন্য চেষ্টা করো।",

      "The harder you work for something, the greater you’ll feel when you achieve it.":
          "যত কঠোর পরিশ্রম করবে, সফল হলে তত বেশি আনন্দ পাবে।",

      "Dream big and dare to fail.":
          "বড় স্বপ্ন দেখো এবং ব্যর্থ হওয়ার সাহস রাখো।",

      "Success is not in what you have, but who you are.":
          "সাফল্য তোমার কাছে কী আছে তাতে নয়, তুমি কে তাতে।",

      "A positive attitude causes a chain reaction of positive thoughts, events, and outcomes.":
          "একটি ইতিবাচক মনোভাব ইতিবাচক চিন্তা, ঘটনা এবং ফলাফলের শৃঙ্খল সৃষ্টি করে।",

      "The only limit to our realization of tomorrow will be our doubts of today.":
          "আগামীকাল অর্জনের একমাত্র সীমা হলো আজকের আমাদের সন্দেহ।",

      "Strength does not come from physical capacity. It comes from an indomitable will.":
          "শক্তি আসে না শারীরিক সামর্থ্য থেকে, আসে অদম্য ইচ্ছাশক্তি থেকে।",

      "The best way to predict the future is to create it.":
          "ভবিষ্যৎ অনুমান করার সেরা উপায় হলো সেটিকে তৈরি করা।",

      "The function of leadership is to produce more leaders, not more followers.":
          "নেতৃত্বের কাজ হলো আরও নেতা তৈরি করা, অনুসারী নয়।",

      "You are never too old to set another goal or to dream a new dream.":
          "নতুন লক্ষ্য নির্ধারণ বা নতুন স্বপ্ন দেখার জন্য তুমি কখনোই বেশি বয়স্ক নও।",

      "To improve is to change; to be perfect is to change often.":
          "উন্নতি মানে পরিবর্তন; আর পরিপূর্ণতা মানে বারবার পরিবর্তন।",

      "Stay positive, work hard, make it happen.":
          "ইতিবাচক থাকো, কঠোর পরিশ্রম করো, সফলতা অর্জন করো।",

      "Gratitude is not only the greatest of virtues but the parent of all others.":
          "কৃতজ্ঞতা শুধু সর্বোচ্চ গুণ নয়, বরং সব গুণের জননী।",

      "The mind is everything. What you think you become.":
          "মনই সবকিছু। তুমি যা ভাবো, তাই তুমি হয়ে ওঠো।",

      "An investment in knowledge pays the best interest.":
          "জ্ঞান অর্জনে বিনিয়োগই সর্বোত্তম লাভ দেয়।",

      "You gain strength, courage, and confidence by every experience in which you really stop to look fear in the face.":
          "প্রত্যেক অভিজ্ঞতায় তুমি শক্তি, সাহস ও আত্মবিশ্বাস অর্জন করো যখন ভয়কে সরাসরি মোকাবিলা করো।",

      "Success is not final, failure is not fatal: It is the courage to continue that counts.":
          "সাফল্য চূড়ান্ত নয়, ব্যর্থতা মারাত্মক নয়; চলতে থাকার সাহসটাই আসল।",

      "The secret of success is to do the common thing uncommonly well.":
          "সাফল্যের রহস্য হলো সাধারণ কাজ অসাধারণভাবে করা।",

      "Don’t limit your challenges. Challenge your limits.":
          "তোমার চ্যালেঞ্জ সীমিত করো না, তোমার সীমাবদ্ধতাকেই চ্যালেঞ্জ করো।",

      "What you get by achieving your goals is not as important as what you become by achieving your goals.":
          "লক্ষ্য অর্জনের মাধ্যমে তুমি যা পাও তার চেয়ে বেশি গুরুত্বপূর্ণ তুমি কী হয়ে ওঠো।",

      "The successful warrior is the average man, with laser-like focus.":
          "সফল যোদ্ধা হলো সাধারণ মানুষ, যার মনোযোগ লেজারের মতো তীক্ষ্ণ।",

      "Your attitude determines your direction.":
          "তোমার মনোভাবই তোমার দিক নির্ধারণ করে।",

      "If you can dream it, you can do it.":
          "তুমি যদি কোনো কিছুর স্বপ্ন দেখতে পারো, তবে সেটি করতে পারো।",

      "The greatest glory in living lies not in never falling, but in rising every time we fall.":
          "জীবনের সর্বোচ্চ গৌরব হলো না পড়ে থাকা নয়, বরং প্রতিবার পড়ে গিয়ে আবার উঠা।",

      "Act as if what you do makes a difference. It does.":
          "এমনভাবে কাজ করো যেন তোমার কাজের গুরুত্ব আছে — আসলেই তা আছে।",

      "Leadership is the capacity to translate vision into reality.":
          "নেতৃত্ব মানে দৃষ্টিভঙ্গিকে বাস্তবে রূপ দেওয়ার ক্ষমতা।",

      "You are braver than you believe, stronger than you seem, and smarter than you think.":
          "তুমি যতটা সাহসী মনে করো, তার চেয়ে বেশি সাহসী; যতটা শক্তিশালী ভাবো, তার চেয়ে বেশি শক্তিশালী; আর যতটা বুদ্ধিমান ভাবো, তার চেয়ে বেশি বুদ্ধিমান।",

      "The only way to make sense out of change is to plunge into it, move with it, and join the dance.":
          "পরিবর্তনকে বোঝার একমাত্র উপায় হলো তাতে ঝাঁপিয়ে পড়া, তার সঙ্গে চলা এবং সেই নাচে যোগ দেওয়া।",

      "Keep your eyes on the stars, and your feet on the ground.":
          "তারার দিকে চোখ রাখো, কিন্তু পা মাটিতে রাখো।",

      "Gratitude is the fairest blossom which springs from the soul.":
          "কৃতজ্ঞতা হলো আত্মা থেকে ফোটা সবচেয়ে সুন্দর ফুল।",

      "A strong positive mental attitude will create more miracles than any wonder drug.":
          "একটি দৃঢ় ইতিবাচক মানসিকতা যেকোনো আশ্চর্য ঔষধের চেয়েও বেশি অলৌকিক কাজ করে।",

      "Education is the most powerful weapon which you can use to change the world.":
          "শিক্ষাই সেই সবচেয়ে শক্তিশালী অস্ত্র, যা দিয়ে তুমি পৃথিবীকে পরিবর্তন করতে পারো।",

      "It takes courage to grow up and become who you really are.":
          "বড় হয়ে আসল তুমি হয়ে উঠতে সাহসের প্রয়োজন।",

      "The harder the conflict, the greater the triumph.":
          "সংঘর্ষ যত কঠিন, বিজয় তত মহান।",

      "Don’t wait for opportunity. Create it.":
          "সুযোগের অপেক্ষা করো না, সুযোগ তৈরি করো।",

      "Great things never come from comfort zones.":
          "মহান কিছু কখনোই আরামের অঞ্চলে থেকে আসে না।",

      // "The future belongs to those who believe in the beauty of their dreams.":
      // "ভবিষ্যৎ তাদেরই, যারা তাদের স্বপ্নের সৌন্দর্যে বিশ্বাস রাখে।",
      "Success usually comes to those who are too busy to be looking for it.":
          "সাফল্য সাধারণত তাদের কাছেই আসে, যারা এটিকে খোঁজার সময় পায় না।",

      "A bad attitude is like a flat tire. You can’t go anywhere until you change it.":
          "একটি খারাপ মনোভাব হলো ফাঁপা টায়ারের মতো — যতক্ষণ না বদলাও, ততক্ষণ কোথাও যেতে পারবে না।",

      // "You are never too old to set another goal or to dream a new dream.":
      // "নতুন লক্ষ্য স্থির করা বা নতুন স্বপ্ন দেখার জন্য তুমি কখনোই বেশি বয়স্ক নও।",
      "Do not judge me by my success, judge me by how many times I fell down and got back up again.":
          "আমার সাফল্য দিয়ে আমাকে বিচার করো না, বরং আমি কতবার পড়ে গিয়ে আবার উঠেছি তা দিয়ে বিচার করো।",

      "What lies behind us and what lies before us are tiny matters compared to what lies within us.":
          "আমাদের পেছনে বা সামনে যা আছে তা তুচ্ছ, আমাদের ভেতরে যা আছে তার তুলনায়।",

      "The challenge of leadership is to be strong, but not rude; be kind, but not weak; be bold, but not a bully; be thoughtful, but not lazy; be humble, but not timid; be proud, but not arrogant; have humor, but without folly.":
          "নেতৃত্বের চ্যালেঞ্জ হলো শক্ত হও, কিন্তু অমার্জিত নয়; দয়ালু হও, কিন্তু দুর্বল নয়; সাহসী হও, কিন্তু অহঙ্কারী নয়; চিন্তাশীল হও, কিন্তু অলস নয়; বিনয়ী হও, কিন্তু ভীরু নয়; গর্বিত হও, কিন্তু উদ্ধত নয়; হাস্যরসিক হও, কিন্তু নির্বোধ নয়।",

      "The only person you are destined to become is the person you decide to be.":
          "তুমি যাকে হওয়ার জন্য নির্ধারিত, সে-ই তুমি, যদি তুমি তা হতে চাও।",

      "Your life does not get better by chance, it gets better by change.":
          "তোমার জীবন ভাগ্যের কারণে নয়, পরিবর্তনের কারণে ভালো হয়।",

      "Positive anything is better than negative nothing.":
          "ইতিবাচক কিছু নেতিবাচক কিছুই না থাকার চেয়ে ভালো।",

      "Gratitude unlocks the fullness of life. It turns what we have into enough, and more.":
          "কৃতজ্ঞতা জীবনের পূর্ণতাকে উন্মোচন করে। এটি আমাদের যা আছে তা যথেষ্ট করে তোলে, বরং তার চেয়েও বেশি।",

      // "The only limit to our realization of tomorrow will be our doubts of today.":
      // "আগামীকাল অর্জনের সীমা নির্ধারণ করে আজকের আমাদের সন্দেহ।",
      "The beautiful thing about learning is that no one can take it away from you.":
          "শেখার সবচেয়ে সুন্দর দিক হলো কেউই এটি তোমার কাছ থেকে কেড়ে নিতে পারে না।",

      "Courage is grace under pressure.":
          "চাপের মধ্যেও সৌন্দর্য বজায় রাখা হলো সাহস।",

      "Energy and persistence conquer all things.":
          "শক্তি ও অধ্যবসায় সবকিছু জয় করে।",

      "The way to get started is to quit talking and begin doing.":
          "শুরু করার উপায় হলো কথা বলা বন্ধ করে কাজ শুরু করা।",

      // "Don’t watch the clock; do what it does. Keep going.":
      // "ঘড়ির দিকে তাকিও না; যেমন ঘড়ি চলে, তেমনই চলতে থাকো।",
      "You miss 100% of the shots you don’t take.":
          "তুমি যেসব সুযোগ নাও না, তার ১০০%ই তুমি হারাও।",

      "The successful person has the habit of doing the things failures don’t like to do.":
          "সফল ব্যক্তির অভ্যাস হলো সেই কাজগুলো করা, যা ব্যর্থরা করতে পছন্দ করে না।",

      "We cannot change our past. We can not change the fact that people act in a certain way. We can not change the inevitable. The only thing we can do is play on the one string we have, and that is our attitude.":
          "আমরা অতীত বদলাতে পারি না, মানুষ কেমন আচরণ করে তাও বদলাতে পারি না, অনিবার্যতাও বদলাতে পারি না। যা আমাদের হাতে আছে তা হলো আমাদের মনোভাব।",

      "All our dreams can come true, if we have the courage to pursue them.":
          "আমাদের সব স্বপ্ন পূরণ হতে পারে, যদি আমরা তা অনুসরণ করার সাহস রাখি।",

      "It’s not whether you get knocked down, it’s whether you get up.":
          "পড়ে যাওয়া নয়, আবার উঠে দাঁড়ানোই আসল ব্যাপার।",

      "The only limit to your impact is your imagination and commitment.":
          "তোমার প্রভাবের একমাত্র সীমা হলো তোমার কল্পনা এবং অঙ্গীকার।",

      "Innovation distinguishes between a leader and a follower.":
          "উদ্ভাবনই একজন নেতা ও অনুসারীর মধ্যে পার্থক্য সৃষ্টি করে।",

      // "Act as if what you do makes a difference. It does.":
      // "এমনভাবে কাজ করো যেন তোমার কাজের গুরুত্ব আছে — আসলেই তা আছে।",
      "Progress is impossible without change, and those who cannot change their minds cannot change anything.":
          "পরিবর্তন ছাড়া অগ্রগতি অসম্ভব, যারা তাদের মন বদলাতে পারে না তারা কিছুই বদলাতে পারে না।",

      "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.":
          "নৈরাশ্যবাদী প্রতিটি সুযোগে সমস্যা দেখে, আশাবাদী প্রতিটি সমস্যায় সুযোগ দেখে।",

      "When I started counting my blessings, my whole life turned around.":
          "যখন আমি আমার আশীর্বাদ গুনতে শুরু করলাম, তখনই আমার জীবন বদলে গেল।",

      // "Whether you think you can or you think you can’t, you’re right.":
      // "তুমি ভাবো পারবে বা পারবে না — দুটোই ঠিক, কারণ সেটাই তোমার মনোভাব।",
      "The more that you read, the more things you will know. The more that you learn, the more places you’ll go.":
          "তুমি যত বেশি পড়বে, তত বেশি জানবে; যত বেশি শিখবে, তত বেশি এগোবে।",

      "Courage is the most important of all the virtues because, without courage, you can’t practice any other virtue consistently.":
          "সব গুণের মধ্যে সাহসই সবচেয়ে গুরুত্বপূর্ণ, কারণ সাহস ছাড়া অন্য কোনো গুণ ধারাবাহিকভাবে চর্চা করা যায় না।",

      "Never give up on a dream just because of the time it will take to accomplish it. The time will pass anyway.":
          "কোনো স্বপ্ন ত্যাগ কোরো না শুধুমাত্র এটি পূর্ণ হতে সময় লাগবে বলে। সময় তো যেভাবেই হোক কেটে যাবে।",

      "Success is not how high you have climbed, but how you make a positive difference to the world.":
          "সাফল্য হলো না তুমি কত উপরে উঠেছো, বরং তুমি পৃথিবীতে কতটা ইতিবাচক পরিবর্তন এনেছো।",

      "The only place where success comes before work is in the dictionary.":
          "সাফল্য কাজের আগে আসে কেবল অভিধানে।",

      "You don’t have to be great to start, but you have to start to be great.":
          "শুরু করতে মহান হওয়া লাগে না, কিন্তু মহান হতে হলে শুরু করতে হয়।",

      "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.":
          "অতীতে বাস কোরো না, ভবিষ্যতের স্বপ্ন দেখো না, বর্তমান মুহূর্তে মনোযোগ দাও।",

      "The greatest discovery of all time is that a person can change his future by merely changing his attitude.":
          "সবচেয়ে বড় আবিষ্কার হলো — মানুষ শুধু নিজের মনোভাব বদলে ভবিষ্যৎ বদলাতে পারে।",

      "Dream big. Start small. Act now.":
          "বড় স্বপ্ন দেখো। ছোট থেকে শুরু করো। এখনই কাজ শুরু করো।",
    };

    return map[english];
  }
}
