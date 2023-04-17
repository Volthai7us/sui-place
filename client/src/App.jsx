import { useEffect, useState } from 'react'

import { GithubPicker, BlockPicker, ChromePicker } from 'react-color'
import { useWallet } from '@suiet/wallet-kit'
import Layout from './components/Layout'
import { getPixels, changePixelTransaction } from './api'

function App() {
    const [loading, setLoading] = useState(true)
    const [color, setColor] = useState('#fff')
    const [grid, setGrid] = useState([])
    const wallet = useWallet()

    const fetchPixels = async () => {
        setLoading(true)
        await getPixels().then((res) => {
            const newGrid = []
            while (res.length) newGrid.push(res.splice(0, 32))
            setGrid(newGrid)
        })
        setLoading(false)
    }

    const changeColor = async (i, j) => {
        const tx = await changePixelTransaction(i, j, color)
        await wallet.signAndExecuteTransactionBlock({
            transactionBlock: tx,
        })
    }

    useEffect(() => {
        fetchPixels()
    }, [])

    return (
        <Layout>
            <div className="bg-black flex flex-col space-y-10 justify-center py-10">
                <ChromePicker
                    className="mx-auto"
                    color={color}
                    onChange={(color) => {
                        setColor(color.hex)
                    }}
                />
                {loading && (
                    <div className="mx-auto text-white text-4xl ">
                        Loading...
                    </div>
                )}
                {!loading && (
                    <div className="grid mx-auto">
                        {grid.map((row, i) => (
                            <div className="flex flex-row " key={i}>
                                {row.map((col, j) => {
                                    const pixel = parseInt(col).toString(16)
                                    return (
                                        <div
                                            onClick={() => changeColor(i, j)}
                                            key={j}
                                            className="p-2 border border-gray-200"
                                            style={{ background: '#' + pixel }}
                                        />
                                    )
                                })}
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </Layout>
    )
}

export default App
