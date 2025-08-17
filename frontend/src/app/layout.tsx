import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })

export const metadata: Metadata = {
  title: 'Enterprise Expense System',
  description: 'Modern expense management system for enterprises',
  keywords: ['expense', 'management', 'enterprise', 'finance'],
  authors: [{ name: 'Enterprise Expense System Team' }],
  creator: 'Enterprise Expense System',
  publisher: 'Enterprise Expense System',
  robots: {
    index: false,
    follow: false,
  },
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },
  manifest: '/site.webmanifest',
  viewport: {
    width: 'device-width',
    initialScale: 1,
    maximumScale: 1,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang='en' className={inter.variable}>
      <body className='min-h-screen bg-background font-sans antialiased'>
        <div id='root'>
          {children}
        </div>
      </body>
    </html>
  )
}