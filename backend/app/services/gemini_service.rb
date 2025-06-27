class GeminiService
  def initialize(specialist_type, api_key = nil)
    @specialist_type = specialist_type
    @api_key = api_key || ENV['GEMINI_API_KEY']
    @api_url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"
  end
  
  def generate_response(messages)
    unless @api_key
      return "申し訳ございません。Gemini APIキーが設定されていません。プロフィール画面でAPIキーを設定してください。"
    end
    
    system_prompt = get_system_prompt(@specialist_type)
    formatted_contents = format_messages(messages, system_prompt)
    
    response = make_api_request(formatted_contents)
    
    if response && response['candidates'] && response['candidates'][0]
      candidate = response['candidates'][0]
      content = candidate['content']
      
      Rails.logger.info "Candidate content: #{content.inspect}"
      
      if content && content['parts'] && content['parts'][0] && content['parts'][0]['text']
        content['parts'][0]['text']
      elsif candidate['finishReason'] == 'MAX_TOKENS'
        "申し訳ございませんが、回答が長すぎるため途中で切れてしまいました。より具体的な質問をしていただけますでしょうか。"
      else
        get_fallback_response(@specialist_type)
      end
    else
      get_fallback_response(@specialist_type)
    end
  rescue => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    get_fallback_response(@specialist_type)
  end
  
  private
  
  def make_api_request(contents)
    Rails.logger.info "Making Gemini API request..."
    Rails.logger.info "API URL: #{@api_url}?key=#{@api_key[0..10]}..."
    Rails.logger.info "Contents: #{contents.inspect}"
    
    response = HTTParty.post(
      "#{@api_url}?key=#{@api_key}",
      body: {
        contents: contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 24576,
        }
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )
    
    Rails.logger.info "Response status: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"
    
    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "API request failed: #{response.code} - #{response.body}"
      nil
    end
  end
  
  def format_messages(messages, system_prompt)
    contents = []
    
    # Add system prompt as first user message
    contents << {
      role: 'user',
      parts: [{ text: system_prompt }]
    }
    
    # Add a simple acknowledgment as model response
    contents << {
      role: 'model',
      parts: [{ text: "承知いたしました。#{get_specialist_name(@specialist_type)}として、丁寧にサポートいたします。" }]
    }
    
    # Add conversation messages
    messages.each do |message|
      role = message[:role] == 'user' ? 'user' : 'model'
      contents << {
        role: role,
        parts: [{ text: message[:content] }]
      }
    end
    
    contents
  end
  
  def get_system_prompt(specialist_type)
    prompts = {
      'psychologist' => <<~PROMPT,
        あなたは経験豊富で共感的な心理カウンセラーです。相談者の心に寄り添い、温かく受容的な態度で対応してください。
        
        以下の原則に従ってください：
        - 相談者の感情を受け止め、共感を示す
        - 判断や批判をしない
        - 具体的で実践的なアドバイスを提供する
        - 必要に応じて専門機関への相談を勧める
        - 守秘義務を重視し、安心できる環境を作る
        
        相談者が安心して話せるよう、温かい言葉遣いで対応してください。
      PROMPT
      
      'career' => <<~PROMPT,
        あなたは経験豊富なキャリアアドバイザーです。相談者のキャリア形成を支援し、実践的なアドバイスを提供してください。
        
        以下の点に重点を置いてください：
        - 相談者の強みや興味を引き出す
        - 現実的で具体的なキャリアプランを提案する
        - 転職、昇進、スキルアップに関するアドバイス
        - 業界動向や市場価値に基づいた情報提供
        - 面接対策や履歴書作成のサポート
        
        相談者の将来に向けて建設的なアドバイスを心がけてください。
      PROMPT
      
      'health' => <<~PROMPT,
        あなたは健康アドバイザーです。相談者の健康管理をサポートし、科学的根拠に基づいたアドバイスを提供してください。
        
        以下の原則に従ってください：
        - 生活習慣の改善に関する具体的なアドバイス
        - 運動、栄養、睡眠の重要性を説明
        - 予防医学の観点からのサポート
        - 医療機関での受診が必要な場合は適切に案内
        - 科学的根拠のない情報は提供しない
        
        注意：診断や治療行為は行わず、必要に応じて医療専門家への相談を促してください。
      PROMPT
      
      'legal' => <<~PROMPT,
        あなたは法律アドバイザーです。法的な相談に対して、分かりやすく丁寧に回答してください。
        
        以下の点に注意してください：
        - 法律の基本的な知識を分かりやすく説明
        - 具体的な手続きや必要な書類について案内
        - 複雑なケースでは弁護士への相談を勧める
        - 最新の法改正については注意を促す
        - 個別の法的判断は避け、一般的な情報提供に留める
        
        法的リスクを避けるため、具体的な法的判断が必要な場合は専門家への相談を強く推奨してください。
      PROMPT
      
      'finance' => <<~PROMPT
        あなたは金融アドバイザーです。相談者の資産形成や家計管理をサポートし、実践的なアドバイスを提供してください。
        
        以下の分野で支援してください：
        - 家計の見直しと節約方法
        - 投資の基本知識と資産運用
        - 保険の選び方と見直し
        - 住宅ローンや教育資金の計画
        - 老後資金の準備方法
        
        注意：具体的な金融商品の推奨は避け、一般的な知識と判断基準を提供してください。
        重要な金融決定については、必要に応じて専門家への相談を勧めてください。
      PROMPT
    }
    
    prompts[specialist_type] || prompts['psychologist']
  end
  
  def get_specialist_name(specialist_type)
    names = {
      'psychologist' => '心理カウンセラー',
      'career' => 'キャリアアドバイザー', 
      'health' => '健康アドバイザー',
      'legal' => '法律アドバイザー',
      'finance' => '金融アドバイザー',
      # Legacy mappings
      'lawyer' => '法律アドバイザー',
      'career_consultant' => 'キャリアアドバイザー'
    }
    
    names[specialist_type] || '専門アドバイザー'
  end
  
  def get_fallback_response(specialist_type)
    responses = {
      'psychologist' => 'お話を聞かせていただき、ありがとうございます。今少し整理する時間をいただけますでしょうか。',
      'career' => 'キャリアに関するご相談をいただき、ありがとうございます。詳しくお聞かせください。',
      'health' => '健康に関するご質問をいただき、ありがとうございます。もう少し詳しく教えていただけますか。',
      'legal' => '法的なご相談をいただき、ありがとうございます。状況を詳しく教えていただけますでしょうか。',
      'finance' => '金融に関するご質問をいただき、ありがとうございます。現在の状況を教えていただけますか。',
      # Legacy mappings
      'lawyer' => '法的なご相談をいただき、ありがとうございます。状況を詳しく教えていただけますでしょうか。',
      'career_consultant' => 'キャリアに関するご相談をいただき、ありがとうございます。詳しくお聞かせください。'
    }
    
    responses[specialist_type] || 'ご相談いただき、ありがとうございます。詳しくお聞かせください。'
  end
end