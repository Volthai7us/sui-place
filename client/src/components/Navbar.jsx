import { ConnectButton } from '@suiet/wallet-kit'

export default function Navbar() {
    return (
        <div className="flex flex-row bg-black py-4 justify-center items-center space-x-10">
            <h1 className="text-white">Sui Place</h1>
            <ConnectButton />
        </div>
    )
}
