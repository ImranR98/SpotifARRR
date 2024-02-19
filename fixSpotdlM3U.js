const fs = require('fs')

const filePath = process.argv[2]

if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    throw 'No/Invalid file argument!'
}

const initContent = fs.readFileSync(filePath).toString()

if (!initContent.startsWith('#EXTM3U')) {
    let finalContent = `#EXTM3U


`

    initContent.split('\n').forEach((mp, i) => {
        if (mp.trim().length > 0) {
            finalContent += `#EXTINF:${i},${mp}
./${mp}


`
        }
    })

    fs.writeFileSync(filePath, finalContent)
}

