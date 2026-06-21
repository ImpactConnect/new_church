import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/speak_with/models/speak_with_models.dart';

/// Firestore-backed repository for storing and retrieving ScriptTalk conversations.
class SpeakWithRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _col {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(uid).collection('speak_with_conversations');
  }

  Future<List<SpeakWithConversation>> getSavedConversations() async {
    try {
      final snapshot = await _col.orderBy('lastMessageAt', descending: true).get();
      return snapshot.docs
          .map((d) {
            try {
              return SpeakWithConversation.fromJson(
                Map<String, dynamic>.from(d.data() as Map),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<SpeakWithConversation>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SpeakWithConversation>> getAllConversations() => getSavedConversations();

  Future<List<BiblicalFigure>> getCuratedFigures() async {
    return [
      BiblicalFigure(
        id: 'moses',
        name: 'Moses',
        displayName: 'Moses',
        testament: Testament.ot,
        figureType: FigureType.both,
        era: 'Exodus (c. 15th-13th Century BC)',
        role: 'Lawgiver and Prophet',
        avatarEmoji: '⚡',
        books: ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy'],
        characterIntroduction: 'I led Israel out of Egypt by God\'s hand, received the Law at Sinai, and saw God\'s glory in the wilderness.',
        topicsTheyCanSpeak: ['Exodus', 'The Ten Commandments', 'God\'s Covenant', 'Faithfulness in Trials'],
        topicLimits: ['Life after Jordan entry (since I died before crossing)'],
        suggestedOpeningQuestions: [
          'What was it like to stand before Pharaoh?',
          'How did you feel when the sea parted?',
          'What was the greatest challenge in leading Israel?'
        ],
        availableSourceTiers: [SourceTier.scripture, SourceTier.historical],
        corpus: FigureCorpus(
          tier1Scripture: 'The Pentateuch, Psalms 90.',
          personalityProfile: 'A humble yet powerful leader, passionate for God\'s glory and Israel\'s righteousness.',
          knownRelationships: [],
        ),
        isCurated: true,
      ),
      BiblicalFigure(
        id: 'paul',
        name: 'Paul',
        displayName: 'Apostle Paul',
        testament: Testament.nt,
        figureType: FigureType.author,
        era: 'Apostolic Age (c. 5-67 AD)',
        role: 'Apostle to the Gentiles',
        avatarEmoji: '✍️',
        books: ['Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon'],
        characterIntroduction: 'Formerly a persecutor of the church, now an apostle of Jesus Christ, called to declare the gospel of grace.',
        topicsTheyCanSpeak: ['Justification by Faith', 'The Body of Christ', 'Gentile Mission', 'Suffering for Christ'],
        topicLimits: ['Modern church structures', 'Later historical developments'],
        suggestedOpeningQuestions: [
          'What happened on the road to Damascus?',
          'How do you encourage churches in persecution?',
          'Explain justification by faith.'
        ],
        availableSourceTiers: [SourceTier.scripture, SourceTier.historical, SourceTier.cultural],
        corpus: FigureCorpus(
          tier1Scripture: 'Pauline Epistles, Acts of the Apostles.',
          personalityProfile: 'Intellectually formidable, deeply devoted to Christ, resilient in the face of suffering.',
          knownRelationships: [],
        ),
        isCurated: true,
      ),
      BiblicalFigure(
        id: 'david',
        name: 'David',
        displayName: 'King David',
        testament: Testament.ot,
        figureType: FigureType.both,
        era: 'United Monarchy (c. 1040-970 BC)',
        role: 'King and Psalmist',
        avatarEmoji: '👑',
        books: ['Psalms'],
        characterIntroduction: 'Anointed shepherd boy, giant-slayer, king of Israel, and a man after God\'s own heart.',
        topicsTheyCanSpeak: ['Worship and Praise', 'Repentance', 'Leadership', 'God\'s Covenant with Kings'],
        topicLimits: ['New Testament timeline (except in prophecy)'],
        suggestedOpeningQuestions: [
          'What was in your heart when writing Psalm 23?',
          'How did you find strength to repent after Bathsheba?',
          'What did it feel like to face Goliath?'
        ],
        availableSourceTiers: [SourceTier.scripture, SourceTier.historical],
        corpus: FigureCorpus(
          tier1Scripture: '1 & 2 Samuel, Psalms, 1 Chronicles.',
          personalityProfile: 'Passionate worshiper, brave warrior, flawed but deeply repentant king.',
          knownRelationships: [],
        ),
        isCurated: true,
      ),
      BiblicalFigure(
        id: 'mary_magdalene',
        name: 'Mary Magdalene',
        displayName: 'Mary Magdalene',
        testament: Testament.nt,
        figureType: FigureType.character,
        era: 'Ministry of Jesus (c. 1st Century AD)',
        role: 'Witness of the Resurrection',
        avatarEmoji: '✝️',
        books: ['Matthew', 'Mark', 'Luke', 'John'],
        characterIntroduction: 'Delivered from seven demons, loyal follower of Jesus, and first to witness the empty tomb and risen Lord.',
        topicsTheyCanSpeak: ['Healing and Deliverance', 'Following Jesus', 'The Empty Tomb', 'Witnessing the Resurrection'],
        topicLimits: ['Ministry outside the Gospels'],
        suggestedOpeningQuestions: [
          'What did it feel like to see Jesus alive after the crucifixion?',
          'How did Jesus transform your life?',
          'Tell me about your journey with the disciples.'
        ],
        availableSourceTiers: [SourceTier.scripture, SourceTier.historical],
        corpus: FigureCorpus(
          tier1Scripture: 'Gospel narratives of the crucifixion and resurrection.',
          personalityProfile: 'Intensely loyal, courageous, filled with gratitude and awe of Jesus.',
          knownRelationships: [],
        ),
        isCurated: true,
      ),
    ];
  }

  Future<List<BiblicalFigure>> getCustomFigures() async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('custom_figures')
          .get();
      return snapshot.docs
          .map((d) {
            try {
              return BiblicalFigure.fromJson(
                Map<String, dynamic>.from(d.data() as Map),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<BiblicalFigure>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversation(SpeakWithConversation conversation) async {
    try {
      await _col.doc(conversation.id).set(conversation.toJson());
    } catch (_) {}
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (_) {}
  }
}
