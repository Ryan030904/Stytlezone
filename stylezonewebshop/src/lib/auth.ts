import {
    GoogleAuthProvider,
    signInWithPopup,
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    updateProfile,
    signOut as firebaseSignOut,
} from "firebase/auth";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { auth, db } from "./firebase";

const googleProvider = new GoogleAuthProvider();

/**
 * Check if user account is banned.
 * Throws an error with ban reason if banned.
 */
async function checkBanStatus(uid: string): Promise<void> {
    const userRef = doc(db, "users", uid);
    const userSnap = await getDoc(userRef);

    if (userSnap.exists()) {
        const data = userSnap.data();
        if (data?.isBanned === true) {
            const reason = data?.banReason || "Vi phạm chính sách cộng đồng";
            // Sign out immediately
            await firebaseSignOut(auth);
            throw new Error(
                `Tài khoản của bạn đã bị khóa do vi phạm chính sách.\n\nLý do: ${reason}\n\nVui lòng liên hệ bộ phận hỗ trợ để biết thêm chi tiết.`
            );
        }
    }
}

/**
 * Sign in with Google popup.
 * On success, upsert user doc in Firestore `users` collection.
 * Admin accounts are treated as regular "user" role on webshop.
 */
export async function signInWithGoogle() {
    const result = await signInWithPopup(auth, googleProvider);
    const user = result.user;

    const userRef = doc(db, "users", user.uid);
    const userSnap = await getDoc(userRef);

    if (!userSnap.exists()) {
        // New user — create doc with role "user"
        await setDoc(userRef, {
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            role: "user", // Always "user" on webshop, even if admin elsewhere
            provider: "google",
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        });
    } else {
        // Check if banned before allowing login
        await checkBanStatus(user.uid);

        // Existing user — update last login info
        await setDoc(
            userRef,
            {
                displayName: user.displayName,
                photoURL: user.photoURL,
                updatedAt: serverTimestamp(),
            },
            { merge: true }
        );
    }

    return user;
}

/**
 * Sign out the current user.
 */
export async function signOutUser() {
    return firebaseSignOut(auth);
}

/**
 * Sign in with email and password.
 */
export async function signInWithEmail(email: string, password: string) {
    const result = await signInWithEmailAndPassword(auth, email, password);

    // Check if banned
    await checkBanStatus(result.user.uid);

    return result.user;
}

/**
 * Register a new user with email and password.
 * Creates a Firestore user doc on success.
 */
export async function registerWithEmail(email: string, password: string, displayName: string) {
    const result = await createUserWithEmailAndPassword(auth, email, password);
    const user = result.user;

    // Update Firebase Auth profile
    await updateProfile(user, { displayName });

    // Create Firestore user doc
    const userRef = doc(db, "users", user.uid);
    await setDoc(userRef, {
        uid: user.uid,
        email: user.email,
        displayName,
        photoURL: null,
        role: "user",
        provider: "email",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
    });

    return user;
}
