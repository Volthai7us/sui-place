import { JsonRpcProvider, Connection, TransactionBlock } from '@mysten/sui.js'
import { BCS, getSuiMoveConfig } from '@mysten/bcs'

let connection = new Connection({
    fullnode: 'https://fullnode.testnet.sui.io:443',
})

const provider = new JsonRpcProvider(connection)
const bcs = new BCS(getSuiMoveConfig())

const PACKAGE_ID =
    '0xede2519afca7766a4b2e1867bd86cae124a864fc6c9487249f46d2ff42d69a2f'
const GAME_ID =
    '0x5f17e1af414f0e763ec87ab7eecf919359ec2481a9c37e26d484bb5767dc1f76'
const GAME_SIZE_X = 32
const GAME_SIZE_Y = 32

export const getPixels = async () => {
    const block = new TransactionBlock()
    block.moveCall({
        target: `${PACKAGE_ID}::game::get_pixels`,
        arguments: [
            block.pure(GAME_SIZE_X),
            block.pure(GAME_SIZE_Y),
            block.object(GAME_ID),
        ],
    })

    return await provider
        .devInspectTransactionBlock({
            transactionBlock: block,
            sender: '0x7777777777777777777777777777777777777777777777777777777777777777',
        })
        .then((pixels) => {
            if (pixels.error) {
                console.log(pixels.error)
                return []
            }
            if (pixels.effects.status.status === 'success') {
                const values = pixels.results[0].returnValues.map((value) => {
                    const type = value[1]
                    const data = Uint8Array.from(value[0])
                    const result = bcs.de(type, data, 'hex')
                    return result
                })

                if (values.length === 0) {
                    return []
                }

                return values[0]
            }

            return []
        })
        .catch((err) => {
            console.log(err)
            return []
        })
}

export const changePixelTransaction = async (x, y, color) => {
    const block = new TransactionBlock()
    const color_ = parseInt('0x' + color.substring(1), 16)
    console.log(color_)

    block.moveCall({
        target: `${PACKAGE_ID}::game::set_pixel`,
        arguments: [
            block.pure(x + y * GAME_SIZE_X),
            block.pure(color_),
            block.object(GAME_ID),
        ],
    })

    return block
}
