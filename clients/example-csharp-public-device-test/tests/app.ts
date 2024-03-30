import { spawn, ChildProcessWithoutNullStreams } from "child_process";

export interface Claims {
    [key: string]: string;
}

export function startApp(): { verificationUrlPromise: Promise<string>, claimsPromise: Promise<Claims> } {
    let resolveVerificationUrl: (value: string) => void;
    let rejectVerificationUrl: (reason?: Error) => void;
    let resolveClaims: (value: Claims) => void;
    let rejectClaims: (reason?: Error) => void;

    const verificationUrlPromise = new Promise((resolve: (value: string) => void, reject) => {
        resolveVerificationUrl = resolve;
        rejectVerificationUrl = reject;
    });

    const claimsPromise = new Promise((resolve: (value: Claims) => void, reject) => {
        resolveClaims = resolve;
        rejectClaims = reject;
    });

    const app: ChildProcessWithoutNullStreams = spawn("./ExampleCsharpPublicDevice");

    const claims: Claims = {};

    let partialLine = "";

    app.stdout.on("data", (data: Buffer) => {
        const lines = (partialLine + data.toString("utf-8")).split("\n");
        partialLine = lines.pop() ?? "";
        for (const line of lines) {
            const verificationUrlMatch = line.match(/VerificationUriComplete: (?<url>.+)/);
            if (verificationUrlMatch?.groups) {
                const url = verificationUrlMatch.groups.url;
                if (url) {
                    resolveVerificationUrl(url);
                }
            }
            const claimMatch = line.match(/IdToken Claim (?<name>.+?): (?<value>.+)/);
            if (claimMatch?.groups) {
                const name = claimMatch.groups.name;
                const value = claimMatch.groups.value;
                claims[name] = value;
            }
        }
    });

    app.on("error", (err: Error) => {
        const error = new Error(`Failed to start child process with error ${err}`, { cause: err });
        rejectVerificationUrl(error);
        rejectClaims(error);
    });

    app.on("close", (code: number, signal: string) => {
        if (code !== 0) {
            const error = new Error(`Child process exited with code ${code}`);
            rejectVerificationUrl(error);
            rejectClaims(error);
        } else {
            resolveClaims(claims);
        }
    });

    return { verificationUrlPromise: verificationUrlPromise, claimsPromise };
}
