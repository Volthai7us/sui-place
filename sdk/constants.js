import { RawSigner, Ed25519Keypair } from "@mysten/sui.js";
import dotenv from "dotenv";
dotenv.config();

export const mnemonic = process.env.MNEMONIC;

const keypair_ed25519 = Ed25519Keypair.deriveKeypair(
  mnemonic,
  "m/44'/784'/0'/0'/0'"
);

export const PACKAGE_ID =
  "0xede2519afca7766a4b2e1867bd86cae124a864fc6c9487249f46d2ff42d69a2f";
export const GAME_ID =
  "0x5f17e1af414f0e763ec87ab7eecf919359ec2481a9c37e26d484bb5767dc1f76";

export const createSigner = async (provider) => {
  const signer = new RawSigner(keypair_ed25519, provider);
  const address = `${await signer.getAddress()}`;

  return { signer, address };
};
