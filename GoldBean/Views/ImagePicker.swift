import SwiftUI
import UIKit
import PhotosUI
import Photos
import AVFoundation

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onError: ((String) -> Void)?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                print("📸 已选择编辑后的图片")
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                print("📸 已选择原始图片")
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ 用户取消选择图片")
            parent.dismiss()
        }
    }
}

// MARK: - 图片选择按钮组件
struct ImageSelectionView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingFullImage = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题区域 - 带移除按钮
            HStack {
                Text("照片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 移除按钮（仅在有图片时显示）
                if selectedImage != nil {
                    Button(action: {
                        // 仅移除图片，不弹出选择器
                        selectedImage = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("移除")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(15)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // 防止按钮样式冲突
                }
            }
            
            if let image = selectedImage {
                // 显示已选择的图片 - 可点击放大，使用独立的按钮包裹
                VStack(spacing: 8) {
                    // 使用 Button 明确控制点击行为
                    Button(action: {
                        // 点击图片时放大查看
                        showingFullImage = true
                    }) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 250)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle()) // 使用 PlainButtonStyle 避免灰色背景
                    
                    // 添加提示文本
                    Text("点击图片可查看大图")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // 显示添加图片按钮
                Button(action: {
                    showingActionSheet = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("添加照片")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("可拍照或从相册选择")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .confirmationDialog("选择图片来源", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("拍照") {
                checkCameraPermission()
            }
            
            Button("从相册选择") {
                checkPhotoLibraryPermission()
            }
            
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let image = selectedImage {
                FullScreenImageView(image: image)
            }
        }
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            Button("确定", role: .cancel) {}
            Button("前往设置") {
                openAppSettings()
            }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    // MARK: - 权限检查方法
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            // 已授权，直接打开相册
            imageSourceType = .photoLibrary
            showingImagePicker = true
            print("✅ 照片库权限已授权")
            
        case .notDetermined:
            // 未请求过权限，请求权限
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        imageSourceType = .photoLibrary
                        showingImagePicker = true
                        print("✅ 用户授予照片库权限")
                    } else {
                        showPermissionDeniedAlert(for: "照片库")
                    }
                }
            }
            
        case .denied, .restricted:
            // 权限被拒绝或受限
            showPermissionDeniedAlert(for: "照片库")
            
        @unknown default:
            showPermissionDeniedAlert(for: "照片库")
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // 已授权，直接打开相机
            imageSourceType = .camera
            showingImagePicker = true
            print("✅ 相机权限已授权")
            
        case .notDetermined:
            // 未请求过权限，请求权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        imageSourceType = .camera
                        showingImagePicker = true
                        print("✅ 用户授予相机权限")
                    } else {
                        showPermissionDeniedAlert(for: "相机")
                    }
                }
            }
            
        case .denied, .restricted:
            // 权限被拒绝或受限
            showPermissionDeniedAlert(for: "相机")
            
        @unknown default:
            showPermissionDeniedAlert(for: "相机")
        }
    }
    
    private func showPermissionDeniedAlert(for feature: String) {
        permissionAlertMessage = "需要\(feature)权限才能使用此功能。请前往设置中允许 GoldBean 访问\(feature)。"
        showingPermissionAlert = true
        print("⚠️ \(feature)权限被拒绝")
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
                print("📱 打开应用设置页面")
            }
        }
    }
}

// MARK: - 全屏图片查看器
struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                // 限制缩放范围
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                    }
                                } else if scale > 5 {
                                    withAnimation {
                                        scale = 5
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // 双击重置缩放
                        withAnimation {
                            scale = 1.0
                        }
                    }
                
                Spacer()
            }
        }
    }
}

