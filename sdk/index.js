import {
  JsonRpcProvider,
  Connection,
  TransactionBlock,
  devnetConnection,
  testnetConnection,
  TYPE_TAG,
  VECTOR,
  UID_STRUCT_NAME,
} from "@mysten/sui.js";
import { BCS, getSuiMoveConfig } from "@mysten/bcs";

import { createSigner, PACKAGE_ID, GAME_ID } from "./constants.js";

let connection = new Connection({
  fullnode: "https://fullnode.testnet.sui.io",
});

let provider = new JsonRpcProvider(connection);

const bcs = new BCS(getSuiMoveConfig());

let version = await provider.getRpcApiVersion();
console.log("Version: ", version);
const { signer, address } = await createSigner(provider);

console.log("-".repeat(80));
console.log("Version: ", version);
console.log("Address: ", address);

const createGame = async (x, y, cooldown, timestamp, canvas_periode, ipfs) => {
  const block = new TransactionBlock();
  console.log(x, y, cooldown, timestamp, canvas_periode, ipfs);
  // const pixels = block.makeMoveVec({
  //   objects: extras.map((e) => block.pure(e.num, "u32")),
  // });
  // const indices = block.makeMoveVec({
  //   objects: extras.map((e) => block.pure(e.index, "u64")),
  // });
  block.moveCall({
    target: `${PACKAGE_ID}::game::create_game`,
    arguments: [
      block.pure(ipfs),
      block.pure(x),
      block.pure(y),
      block.pure(4294967040),
      block.pure(cooldown),
      block.pure(timestamp),
      block.pure(canvas_periode),
    ],
  });
  const tx = await signer.signAndExecuteTransactionBlock({
    transactionBlock: block,
    options: {
      showObjectChanges: true,
    },
  });
  console.log(tx);
};

const getPixel = async (x, y) => {
  const block = new TransactionBlock();
  block.moveCall({
    target: `${PACKAGE_ID}::game::get_pixel`,
    arguments: [block.pure(x), block.pure(y), block.object(GAME_ID)],
  });
  const pixel = await provider.devInspectTransactionBlock({
    transactionBlock: block,
    sender:
      "0x7777777777777777777777777777777777777777777777777777777777777777",
  });

  if (pixel.effects.status.status == "success") {
    const value = pixel.results[0].returnValues[0];
    const type = value[1];
    const data = Uint8Array.from(value[0]);
    const result = bcs.de(type, data, "hex");
    console.log(result);
  }
};

const getPixels = async () => {
  const block = new TransactionBlock();
  block.moveCall({
    target: `${PACKAGE_ID}::game::get_pixels`,
    arguments: [block.pure(10), block.pure(10), block.object(GAME_ID)],
  });

  const pixels = await provider.devInspectTransactionBlock({
    transactionBlock: block,
    sender:
      "0x7777777777777777777777777777777777777777777777777777777777777777",
  });

  const values = pixels.results[0].returnValues.map((value) => {
    const type = value[1];
    const data = Uint8Array.from(value[0]);
    const result = bcs.de(type, data, "hex");
    return result;
  });
  console.log(values);
};

const setPixel = async (index, color) => {
  const block = new TransactionBlock();
  block.moveCall({
    target: `${PACKAGE_ID}::game::set_pixel`,
    arguments: [block.pure(index), block.pure(color), block.object(GAME_ID)],
  });
  const tx = await signer.signAndExecuteTransactionBlock({
    transactionBlock: block,
  });
  console.log(tx);
};

const getInfo = async (id) => {
  const block = new TransactionBlock();
  block.moveCall({
    target: `${PACKAGE_ID}::game::get_info`,
    arguments: [block.object(id)],
  });
  const info = await provider
    .devInspectTransactionBlock({
      transactionBlock: block,
      sender:
        "0x7777777777777777777777777777777777777777777777777777777777777777",
    })
    .then((res) => {
      if (res.error) {
        console.log(res.error);
        return false;
      }
      if (res.effects.status.status === "success") {
        const values = res.results[0].returnValues.map((value) => {
          const type = value[1];
          if (type.includes("String") || type.includes("Url")) {
            value = value[0].slice(1);
            const string = value.map((v) => String.fromCharCode(v)).join("");
            return string;
          } else {
            const data = Uint8Array.from(value[0]);
            const result = bcs.de(type, data, "hex");
            return result;
          }
        });
        if (values.length === 0) {
          return false;
        }
        return values;
      }
    })
    .catch((err) => {
      console.log(err);
      return false;
    });

  console.log(info);
};

const command = process.argv[2];
if (command == "getPixel") {
  const x = parseInt(process.argv[3]);
  const y = parseInt(process.argv[4]);
  getPixel(x, y);
} else if (command == "getPixels") {
  getPixels();
} else if (command == "setPixel") {
  const index = parseInt(process.argv[3]);
  const color = parseInt(process.argv[4]);
  setPixel(index, color);
} else if (command == "createGame") {
  const x = parseInt(process.argv[3]);
  const y = parseInt(process.argv[4]);
  const ipfs =
    process.argv[5] || "Qmc9DF2hbPeWMGBYzvY7rjMi4er92SwH2Ta9h7a9kpNh1y";
  // const timestamp = new Date("2023-05-02T00:00:00Z").getTime();
  const timestamp = new Date().getTime();
  const cooldown = process.argv[6] || 30 * 1000;
  const canvas_periode = process.argv[7] || 1440;
  createGame(x, y, cooldown, timestamp, canvas_periode, ipfs);
} else if (command == "getInfo") {
  const id = process.argv[3];
  getInfo(id);
}
