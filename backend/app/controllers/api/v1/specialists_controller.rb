class Api::V1::SpecialistsController < ApplicationController
  def index
    specialists = [
      {
        id: 'psychologist',
        name: '心理カウンセラー',
        description: 'メンタルヘルス、人間関係、ストレス管理などの心理的な悩みについて相談できます。',
        icon: '🧠'
      },
      {
        id: 'career',
        name: 'キャリアアドバイザー',
        description: '転職、昇進、スキルアップ、キャリアプランニングについて相談できます。',
        icon: '💼'
      },
      {
        id: 'health',
        name: '健康アドバイザー',
        description: '生活習慣、運動、栄養、睡眠など健康管理について相談できます。',
        icon: '⚕️'
      },
      {
        id: 'legal',
        name: '法律アドバイザー',
        description: '法的な問題や手続き、権利関係について一般的な情報を提供します。',
        icon: '⚖️'
      },
      {
        id: 'finance',
        name: '金融アドバイザー',
        description: '家計管理、投資、保険、資産運用について相談できます。',
        icon: '💰'
      }
    ]
    
    render json: { specialists: specialists }
  end
end