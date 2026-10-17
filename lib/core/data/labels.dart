/// Rótulos pt-BR para identificadores da PokeAPI. Os dados em si (nomes de golpes,
/// habilidades, itens) continuam em inglês.
library;

abstract final class Labels {
  static const stats = ['PS', 'Ataque', 'Defesa', 'At. Esp.', 'Def. Esp.', 'Velocidade'];
  static const statsShort = ['PS', 'Atq', 'Def', 'AtE', 'DfE', 'Vel'];

  static const categories = {
    'legendary': 'Lendários',
    'mythical': 'Míticos',
    'ultra-beast': 'Ultracriaturas',
    'paradox': 'Paradoxo',
    'starter': 'Iniciais',
    'pseudo-legendary': 'Pseudolendários',
    'baby': 'Bebês',
    'mega': 'Megaevolução',
    'gmax': 'Gigantamax',
    'regional': 'Formas regionais',
  };

  static const regional = {'alola': 'Alola', 'galar': 'Galar', 'hisui': 'Hisui', 'paldea': 'Paldea'};

  static const damageClass = {'physical': 'Físico', 'special': 'Especial', 'status': 'Status'};

  static const moveMethod = {
    'level-up': 'Por nível',
    'machine': 'MT / DT',
    'egg': 'Ovo',
    'tutor': 'Tutor',
    'form-change': 'Mudança de forma',
    'light-ball-egg': 'Ovo (Light Ball)',
    'stadium-surfing-pikachu': 'Stadium',
    'colosseum-purification': 'Purificação',
    'xd-shadow': 'Sombrio (XD)',
    'xd-purification': 'Purificação (XD)',
    'zygarde-cube': 'Cubo Zygarde',
    'train': 'Treino',
  };

  static const evolutionTrigger = {
    'level-up': 'Subir de nível',
    'trade': 'Troca',
    'use-item': 'Usar item',
    'shed': 'Muda (vaga no time)',
    'spin': 'Girar',
    'tower-of-darkness': 'Torre da Escuridão',
    'tower-of-waters': 'Torre das Águas',
    'three-critical-hits': '3 golpes críticos',
    'take-damage': 'Sofrer dano',
    'in-battle-level-up': 'Subir de nível em batalha',
    'agile-style-move': 'Estilo Ágil',
    'strong-style-move': 'Estilo Forte',
    'recoil-damage': 'Dano de recuo',
    'use-move': 'Usar golpe',
    'three-defeated-bisharp': 'Derrotar 3 Bisharp',
    'gimmighoul-coins': 'Moedas de Gimmighoul',
    'meltan-candies': 'Doces de Meltan',
    'unclassified': 'Especial',
  };

  static const timeOfDay = {'day': 'de dia', 'night': 'à noite', 'dusk': 'ao entardecer', 'full-moon': 'na lua cheia'};

  static const growthRate = {
    'slow': 'Lento',
    'medium': 'Médio',
    'fast': 'Rápido',
    'medium-slow': 'Médio-lento',
    'slow-then-very-fast': 'Errático',
    'fast-then-very-slow': 'Flutuante',
  };

  /// Formata altura (decímetros) e peso (hectogramas) da PokeAPI.
  static String height(int dm) => '${(dm / 10).toStringAsFixed(1).replaceAll('.', ',')} m';
  static String weight(int hg) => '${(hg / 10).toStringAsFixed(1).replaceAll('.', ',')} kg';

  /// "#0025"
  static String dexNumber(int n) => '#${n.toString().padLeft(4, '0')}';
}
