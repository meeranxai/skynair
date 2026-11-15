// Simple Node.js script to check Firebase data
const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need to set GOOGLE_APPLICATION_CREDENTIALS)
try {
    admin.initializeApp();
    console.log('✅ Firebase Admin initialized');
} catch (error) {
    console.log('❌ Firebase Admin initialization failed:', error.message);
    process.exit(1);
}

const db = admin.firestore();

async function checkFirebaseData() {
    try {
        console.log('🔍 Checking Firebase Firestore data...\n');

        // Check posts collection
        console.log('1. Checking posts collection...');
        const postsSnapshot = await db.collection('posts').limit(5).get();
        console.log(`   Total posts found: ${postsSnapshot.size}`);

        if (postsSnapshot.size > 0) {
            console.log('   Sample posts:');
            postsSnapshot.forEach((doc, index) => {
                const data = doc.data();
                console.log(`   ${index + 1}. ID: ${doc.id}`);
                console.log(`      Title: ${data.title || 'No title'}`);
                console.log(`      Author ID: ${data.authorId || 'No authorId'}`);
                console.log(`      Post Type: ${data.postType || 'No postType'}`);
                console.log(`      Is Draft: ${data.isDraft || false}`);
                console.log(`      Is Archived: ${data.isArchived || false}`);
                console.log(`      Created: ${data.createdAt ? new Date(data.createdAt.seconds * 1000).toISOString() : 'No date'}`);
                console.log('');
            });
        } else {
            console.log('   ❌ No posts found in database!');
            console.log('   This is likely the root cause of the spinning loader.');
        }

        // Check userProfiles collection
        console.log('2. Checking userProfiles collection...');
        const usersSnapshot = await db.collection('userProfiles').limit(3).get();
        console.log(`   Total users found: ${usersSnapshot.size}`);

        if (usersSnapshot.size > 0) {
            console.log('   Sample users:');
            usersSnapshot.forEach((doc, index) => {
                const data = doc.data();
                console.log(`   ${index + 1}. UID: ${doc.id}`);
                console.log(`      Display Name: ${data.displayName || 'No name'}`);
                console.log(`      Username: ${data.username || 'No username'}`);
                console.log(`      Posts Count: ${data.postsCount || 0}`);
                console.log('');
            });
        }

        // Check if any user has posts
        if (postsSnapshot.size > 0 && usersSnapshot.size > 0) {
            console.log('3. Checking user-post relationships...');
            const userIds = [];
            usersSnapshot.forEach(doc => userIds.push(doc.id));

            for (const userId of userIds.slice(0, 2)) {
                const userPostsSnapshot = await db.collection('posts')
                    .where('authorId', '==', userId)
                    .limit(3)
                    .get();

                console.log(`   User ${userId}: ${userPostsSnapshot.size} posts`);
                if (userPostsSnapshot.size > 0) {
                    userPostsSnapshot.forEach(doc => {
                        const data = doc.data();
                        console.log(`     - ${data.title || 'No title'} (${data.postType || 'unknown type'})`);
                    });
                }
            }
        }

        console.log('\n🎯 Summary:');
        console.log(`   Posts in database: ${postsSnapshot.size}`);
        console.log(`   Users in database: ${usersSnapshot.size}`);

        if (postsSnapshot.size === 0) {
            console.log('\n❌ ROOT CAUSE FOUND: No posts in database!');
            console.log('   Solution: Create some test posts or check if posts are being created properly.');
        } else {
            console.log('\n✅ Posts exist in database. Issue might be:');
            console.log('   - Wrong authorId field values');
            console.log('   - All posts are drafts (isDraft: true)');
            console.log('   - All posts are archived (isArchived: true)');
            console.log('   - Wrong postType (not "media")');
            console.log('   - Firestore rules blocking queries');
        }

    } catch (error) {
        console.error('❌ Error checking Firebase data:', error);
    }
}

checkFirebaseData().then(() => {
    console.log('\n✅ Firebase data check complete');
    process.exit(0);
}).catch(error => {
    console.error('❌ Script failed:', error);
    process.exit(1);
});