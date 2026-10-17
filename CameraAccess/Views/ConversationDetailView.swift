/*
 * Conversation Detail View
 * 对话详情页面
 */

import SwiftUI

struct ConversationDetailView: View {
    let conversation: ConversationRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.secondaryBackground
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("会話の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Conversation info
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "clock")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(conversation.formattedDate)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("メッセージ \(conversation.messageCount)件")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColors.tertiaryBackground.opacity(0.95))
            }
        }
    }
}
