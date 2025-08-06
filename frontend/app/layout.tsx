import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Providers } from './providers'
import { Navbar } from '@/components/layout/Navbar'
import { Sidebar } from '@/components/layout/Sidebar'
import { Toaster } from 'react-hot-toast'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'JuliaSphere - AI Agent Marketplace',
  description: 'Discover, deploy, and visualize AI agents and swarms in the JuliaOS ecosystem',
  keywords: ['AI', 'agents', 'swarms', 'Julia', 'marketplace', 'automation'],
  authors: [{ name: 'JuliaOS Team' }],
  creator: 'JuliaOS',
  openGraph: {
    title: 'JuliaSphere - AI Agent Marketplace',
    description: 'Discover, deploy, and visualize AI agents and swarms in the JuliaOS ecosystem',
    type: 'website',
    locale: 'en_US',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'JuliaSphere - AI Agent Marketplace',
    description: 'Discover, deploy, and visualize AI agents and swarms in the JuliaOS ecosystem',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.className} bg-gray-50 dark:bg-gray-900`}>
        <Providers>
          <div className="flex h-screen overflow-hidden">
            {/* Sidebar */}
            <Sidebar />
            
            {/* Main content area */}
            <div className="flex flex-1 flex-col overflow-hidden">
              {/* Top navigation */}
              <Navbar />
              
              {/* Page content */}
              <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900">
                <div className="container mx-auto px-4 py-6">
                  {children}
                </div>
              </main>
            </div>
          </div>
          
          {/* Toast notifications */}
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              className: 'bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100',
            }}
          />
        </Providers>
      </body>
    </html>
  )
}