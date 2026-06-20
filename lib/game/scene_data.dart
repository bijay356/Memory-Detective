import 'dart:math';

class StoryCase {
  final String id;
  final String title;
  final String description;
  final int difficulty; // 1 to 1000
  final int nodeCount; // Total number of evidence nodes on the corkboard
  final int stringCount; // Total number of red strings to memorize
  final String question;
  final List<String> options;
  final int correctIndex;

  StoryCase({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.nodeCount,
    required this.stringCount,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class SceneDatabase {
  static final List<StoryCase> cases = StoryGenerator.generateCases(1000);
}

class StoryGenerator {
  static final List<String> _themes = [
    'Corporate Fraud',
    'Cyber Warfare',
    'Crypto Heist',
    'Political Espionage',
    'Black Market',
    'Art Forgery',
    'Global Syndicate'
  ];

  static final Map<String, List<String>> _titleTemplates = {
    'Corporate Fraud': [
      'The {person} Embezzlement',
      'Collapse of {location}',
      'The {item} Scandal',
      'Operation {item} Wash'
    ],
    'Cyber Warfare': [
      'The {location} Breach',
      'Zero-Day at {location}',
      'The {person} Hack',
      'Extraction of the {item}'
    ],
    'Crypto Heist': [
      'The 500M {item} Drain',
      'Wallet Breach at {location}',
      'The Silk {location} Takedown',
      'The Phantom {person}'
    ],
    'Political Espionage': [
      'The {location} Leaks',
      'The {item} Dossier',
      'Wiretap on the {person}',
      'The {person} Defection'
    ],
    'Black Market': [
      'Smuggling the {item}',
      'The {location} Cartel',
      'Bust of the {person}',
      'The Underground {item}'
    ],
    'Art Forgery': [
      'The Fake {item}',
      'Heist at the {location}',
      'The Master {person}',
      'The Stolen {item}'
    ],
    'Global Syndicate': [
      'Takedown of the {person}',
      'Raid on {location}',
      'The {item} Conspiracy',
      'The {location} Syndicate'
    ],
  };

  static final List<String> _items = [
    'Offshore Ledger',
    'Encrypted Drive',
    'Classified Blueprints',
    'Bitcoin Wallet',
    'Ransomware Payload',
    'Forged Masterpiece',
    'Syndicate Database',
    'Whistleblower Cache',
    'Burner Phone',
    'Smuggled Artifact',
    'Swiss Bank Codes',
    'Prototype Weapon'
  ];

  static final List<String> _locations = [
    'Silicon Valley Server Farm',
    'Zurich Central Bank',
    'Panama Offshore Firm',
    'Interpol Headquarters',
    'Dark Web Marketplace',
    'Pentagon Sub-basement',
    'Dubai Luxury Penthouse',
    'Tokyo Tech Conglomerate',
    'London Art Gallery',
    'Cayman Islands Vault',
    'Moscow Intelligence Hub',
    'Underground Bunker'
  ];

  static final List<String> _persons = [
    'Rogue CEO',
    'Lead Hacker',
    'Corrupt Senator',
    'Shadow Broker',
    'Cartel Boss',
    'Whistleblower',
    'Double Agent',
    'Master Forger',
    'Syndicate Kingpin',
    'Corrupted AI',
    'Minister of Defense',
    'Anonymous Source'
  ];

  static final List<String> _verbs = [
    'embezzled',
    'leaked',
    'encrypted',
    'laundered',
    'smuggled',
    'forged',
    'hacked',
    'hijacked'
  ];

  static final List<String> _motives = [
    'to manipulate the global markets.',
    'to fund an underground shadow war.',
    'for a billion-dollar cryptocurrency ransom.',
    'to expose the deepest government secrets.',
    'to collapse the international banking system.',
    'for ultimate control over the syndicate.'
  ];

  static List<StoryCase> generateCases(int count) {
    List<StoryCase> cases = [];
    for (int i = 1; i <= count; i++) {
      cases.add(_generateCase(i));
    }
    return cases;
  }

  static StoryCase _generateCase(int level) {
    final rand = Random(level * 999); // Seeded random for consistency

    String theme = _themes[rand.nextInt(_themes.length)];

    List<String> templates = _titleTemplates[theme]!;
    String template = templates[rand.nextInt(templates.length)];
    String item = _items[rand.nextInt(_items.length)];
    String location = _locations[rand.nextInt(_locations.length)];
    String person = _persons[rand.nextInt(_persons.length)];

    String title = template
        .replaceAll('{item}', item)
        .replaceAll('{location}', location)
        .replaceAll('{person}', person);

    String verb = _verbs[rand.nextInt(_verbs.length)];
    String motive = _motives[rand.nextInt(_motives.length)];
    String victim = _persons[rand.nextInt(_persons.length)];

    String description =
        "BREAKING NEWS: A massive outbreak has hit the international wires. Intelligence reports a critical incident at the $location. "
        "It appears the $person successfully $verb the $item $motive "
        "The $victim was caught in the crossfire. Analyze the evidence to uncover the full truth.";

    int qType = rand.nextInt(3);
    String question = '';
    List<String> options = [];
    String correctAns = '';

    if (qType == 0) {
      question =
          "Based on the intelligence briefing, who is the prime suspect responsible for the incident?";
      correctAns = person;
      List<String> wrongs = List.from(_persons)
        ..remove(person)
        ..shuffle(rand);
      options = [correctAns, wrongs[0], wrongs[1], wrongs[2]];
    } else if (qType == 1) {
      question =
          "What critical asset was targeted during the breach at the $location?";
      correctAns = item;
      List<String> wrongs = List.from(_items)
        ..remove(item)
        ..shuffle(rand);
      options = [correctAns, wrongs[0], wrongs[1], wrongs[2]];
    } else {
      question = "Where did this high-profile incident take place?";
      correctAns = location;
      List<String> wrongs = List.from(_locations)
        ..remove(location)
        ..shuffle(rand);
      options = [correctAns, wrongs[0], wrongs[1], wrongs[2]];
    }

    options.shuffle(rand);
    int correctIndex = options.indexOf(correctAns);

    int nodes = 5 + (level ~/ 100);
    int strings = 3 + (level ~/ 100);

    if (nodes > 16) nodes = 16;
    if (strings > 14) strings = 14;

    return StoryCase(
      id: 'case_$level',
      title: title,
      description: description,
      difficulty: level,
      nodeCount: nodes,
      stringCount: strings,
      question: question,
      options: options,
      correctIndex: correctIndex,
    );
  }
}
