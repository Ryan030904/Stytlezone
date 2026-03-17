import { v2 as cloudinary } from "cloudinary";

cloudinary.config({
    cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

export default cloudinary;

/**
 * Upload a file buffer to Cloudinary.
 * @param fileBuffer - The file as a Buffer
 * @param folder - Cloudinary folder path (e.g. "stylezone/avatars")
 * @returns Cloudinary upload result with secure_url, public_id, etc.
 */
export async function uploadToCloudinary(
    fileBuffer: Buffer,
    folder: string = "stylezone/uploads"
) {
    return new Promise<{ secure_url: string; public_id: string; width: number; height: number }>((resolve, reject) => {
        cloudinary.uploader
            .upload_stream(
                {
                    folder,
                    resource_type: "auto",
                },
                (error, result) => {
                    if (error || !result) {
                        reject(error || new Error("Upload failed"));
                    } else {
                        resolve({
                            secure_url: result.secure_url,
                            public_id: result.public_id,
                            width: result.width,
                            height: result.height,
                        });
                    }
                }
            )
            .end(fileBuffer);
    });
}

/**
 * Delete an image from Cloudinary by public_id.
 */
export async function deleteFromCloudinary(publicId: string) {
    return cloudinary.uploader.destroy(publicId);
}
